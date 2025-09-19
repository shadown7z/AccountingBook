import { formProvider, formBindingData } from '@kit.FormKit'
import { Want } from '@kit.AbilityKit'
import { BillService } from './BillService'
import { AccountService } from './AccountService'
import { BillRecord, BillType } from '../model/BillRecord'
import { Account } from '../model/Account'

// 定义卡片数据接口
export interface WidgetData {
  todayIncome: number
  todayExpense: number
  monthIncome: number
  monthExpense: number
  totalBalance: number
  recentBills: BillRecord[]
  lastUpdateTime: string
}

// 定义事件参数接口
interface EventParams {
  amount?: number
  category?: string
}

/**
 * 桌面卡片服务
 * 提供快速记账和数据展示功能
 */
export class WidgetService {
  private static instance: WidgetService
  private billService = BillService.getInstance()
  private accountService = AccountService.getInstance()
  private activeFormIds: Set<string> = new Set()
  
  private constructor() {}
  
  static getInstance(): WidgetService {
    if (!WidgetService.instance) {
      WidgetService.instance = new WidgetService()
    }
    return WidgetService.instance
  }
  
  // 注册活跃的桌面卡片
  registerActiveForm(formId: string): void {
    this.activeFormIds.add(formId)
    console.info(`桌面卡片已注册: ${formId}, 当前活跃卡片数: ${this.activeFormIds.size}`)
  }
  
  // 注销桌面卡片
  unregisterActiveForm(formId: string): void {
    this.activeFormIds.delete(formId)
    console.info(`桌面卡片已注销: ${formId}, 当前活跃卡片数: ${this.activeFormIds.size}`)
  }
  
  /**
   * 获取卡片数据
   */
  async getWidgetData(): Promise<WidgetData> {
    try {
      // 获取今日收支数据
      const today = new Date()
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate())
      const todayEnd = new Date(todayStart.getTime() + 24 * 60 * 60 * 1000 - 1)
      
      const allBills = this.billService.getBillRecords()
      const todayBills = allBills.filter(bill => {
        const billDate = new Date(bill.date)
        return billDate >= todayStart && billDate <= todayEnd
      })
      
      let todayIncome = 0
      let todayExpense = 0
      
      todayBills.forEach(bill => {
        if (bill.type === BillType.INCOME) {
          todayIncome += bill.amount
        } else {
          todayExpense += bill.amount
        }
      })
      
      // 获取本月收支数据
      const monthStart = new Date(today.getFullYear(), today.getMonth(), 1)
      const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0, 23, 59, 59)
      
      const monthBills = allBills.filter(bill => {
        const billDate = new Date(bill.date)
        return billDate >= monthStart && billDate <= monthEnd
      })
      
      let monthIncome = 0
      let monthExpense = 0
      
      monthBills.forEach(bill => {
        if (bill.type === BillType.INCOME) {
          monthIncome += bill.amount
        } else {
          monthExpense += bill.amount
        }
      })
      
      // 获取账户余额
      const accounts = await this.accountService.getAllAccounts()
      const totalBalance = accounts.reduce((sum, account) => sum + account.balance, 0)
      
      // 获取最近记录
      const recentBills = this.billService.getRecentBillRecords(3)
      
      const widgetData: WidgetData = {
        todayIncome,
        todayExpense,
        monthIncome,
        monthExpense,
        totalBalance,
        recentBills,
        lastUpdateTime: new Date().toISOString()
      }
      
      console.info('Widget data generated:', {
        todayIncome,
        todayExpense,
        monthIncome,
        monthExpense,
        totalBalance,
        recentBillsCount: recentBills.length
      })
      
      return widgetData
    } catch (error) {
      console.error('Failed to get widget data:', error)
      const defaultData: WidgetData = {
        todayIncome: 0,
        todayExpense: 0,
        monthIncome: 0,
        monthExpense: 0,
        totalBalance: 0,
        recentBills: [],
        lastUpdateTime: new Date().toISOString()
      }
      return defaultData
    }
  }
  
  /**
   * 快速添加收入记录
   */
  async quickAddIncome(amount: number, category: string = '其他收入'): Promise<boolean> {
    try {
      const accounts = await this.accountService.getAllAccounts()
      const defaultAccount = accounts.find(acc => acc.isDefault) || accounts[0]
      
      if (!defaultAccount) {
        throw new Error('No account available')
      }
      
      const newBill = new BillRecord(amount, BillType.INCOME, category, '快速记账')
      newBill.accountId = defaultAccount.id
      
      // 添加账单记录
      await this.billService.addBillRecord(newBill)
      
      // 更新账户余额
      await this.accountService.updateAccountBalance(defaultAccount.id, amount)
      
      console.info(`Quick income added: ${amount}, account balance updated`)
      return true
    } catch (error) {
      console.error('Failed to quick add income:', error)
      return false
    }
  }
  
  /**
   * 快速添加支出记录
   */
  async quickAddExpense(amount: number, category: string = '其他支出'): Promise<boolean> {
    try {
      const accounts = await this.accountService.getAllAccounts()
      const defaultAccount = accounts.find(acc => acc.isDefault) || accounts[0]
      
      if (!defaultAccount) {
        throw new Error('No account available')
      }
      
      const newBill = new BillRecord(amount, BillType.EXPENSE, category, '快速记账')
      newBill.accountId = defaultAccount.id
      
      // 添加账单记录
      await this.billService.addBillRecord(newBill)
      
      // 更新账户余额（支出为负数）
      await this.accountService.updateAccountBalance(defaultAccount.id, -amount)
      
      console.info(`Quick expense added: ${amount}, account balance updated`)
      return true
    } catch (error) {
      console.error('Failed to quick add expense:', error)
      return false
    }
  }
  
  /**
   * 更新指定卡片数据
   */
  async updateWidget(formId: string): Promise<void> {
    try {
      const widgetData = await this.getWidgetData()
      const formData = this.convertToFormData(widgetData)
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData))
      console.info(`卡片数据更新成功: ${formId}`)
    } catch (error) {
      console.error(`卡片数据更新失败: ${formId}`, error)
    }
  }
  
  /**
   * 更新所有活跃的桌面卡片
   */
  async updateAllActiveWidgets(): Promise<void> {
    try {
      if (this.activeFormIds.size === 0) {
        console.info('当前没有活跃的桌面卡片需要更新')
        return
      }
      
      const widgetData = await this.getWidgetData()
      const formData = this.convertToFormData(widgetData)
      const bindingData = formBindingData.createFormBindingData(formData)
      
      // 批量更新所有活跃的桌面卡片
      const updatePromises = Array.from(this.activeFormIds).map(async (formId) => {
        try {
          await formProvider.updateForm(formId, bindingData)
          console.info(`桌面卡片更新成功: ${formId}`)
        } catch (error) {
          console.error(`桌面卡片更新失败: ${formId}`, error)
        }
      })
      
      await Promise.all(updatePromises)
      console.info(`所有活跃桌面卡片更新完成，共更新 ${this.activeFormIds.size} 个卡片`)
    } catch (error) {
      console.error('批量更新桌面卡片失败:', error)
    }
  }
  
  /**
   * 更新表单数据
   */
  async updateFormData(formId: string, data: Record<string, Object>): Promise<void> {
    try {
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(data))
      console.info('表单数据更新成功')
    } catch (error) {
      console.error('表单数据更新失败:', error)
    }
  }
  
  /**
   * 将WidgetData转换为Record<string, Object>
   */
  private convertToFormData(data: WidgetData): Record<string, Object> {
    const formData: Record<string, Object> = {}
    formData['todayIncome'] = data.todayIncome.toFixed(2)
    formData['todayExpense'] = data.todayExpense.toFixed(2)
    formData['monthIncome'] = data.monthIncome.toFixed(2)
    formData['monthExpense'] = data.monthExpense.toFixed(2)
    formData['totalBalance'] = data.totalBalance.toFixed(2)
    formData['lastUpdate'] = this.formatTime(new Date())
    formData['recentBills'] = JSON.stringify(data.recentBills.map((bill: BillRecord) => this.convertBillToObject(bill)))
    return formData
  }
  
  /**
   * 将账单转换为对象
   */
  private convertBillToObject(bill: BillRecord): Record<string, Object> {
    const billObj: Record<string, Object> = {}
    billObj['type'] = bill.type
    billObj['amount'] = bill.amount.toFixed(2)
    billObj['category'] = bill.category
    billObj['date'] = this.formatDate(new Date(bill.date))
    return billObj
  }
  
  /**
   * 处理卡片事件
   */
  async handleWidgetEvent(formId: string, eventData: Record<string, Object>): Promise<void> {
    try {
      const action = eventData.action as string
      const params = eventData.params as EventParams
      
      switch (action) {
        case 'quickExpense':
          await this.quickAddExpense(params.amount || 0, params.category || '其他')
          break
        case 'quickIncome':
          await this.quickAddIncome(params.amount || 0, params.category || '其他')
          break
        default:
          console.warn('未知的卡片事件:', action)
      }
      
      // 更新卡片数据
      const updatedData = await this.getWidgetData()
      const formData = this.convertToFormData(updatedData)
      await this.updateFormData(formId, formData)
    } catch (error) {
      console.error('处理卡片事件失败:', error)
    }
  }
  
  /**
   * 格式化时间
   */
  private formatTime(date: Date): string {
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
  }
  
  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getMonth() + 1}/${date.getDate()}`
  }
}

/**
 * 卡片配置接口
 */
export interface WidgetConfig {
  showTodayData: boolean
  showMonthData: boolean
  showBalance: boolean
  showRecentBills: boolean
  quickActionEnabled: boolean
  refreshInterval: number // 分钟
}

/**
 * 默认卡片配置
 */
export const DEFAULT_WIDGET_CONFIG: WidgetConfig = {
  showTodayData: true,
  showMonthData: true,
  showBalance: true,
  showRecentBills: true,
  quickActionEnabled: true,
  refreshInterval: 30
}