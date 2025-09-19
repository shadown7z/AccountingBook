import { FormExtensionAbility, formInfo, formProvider, formBindingData } from '@kit.FormKit'
import { Want } from '@kit.AbilityKit'
import { WidgetService } from '../service/WidgetService'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { Configuration } from '@kit.AbilityKit'

// 定义表单数据接口
interface FormData {
  todayIncome: string
  todayExpense: string
  monthIncome: string
  monthExpense: string
  totalBalance: string
  recentBills: Object[]
  lastUpdateTime: string
}

const TAG = 'EntryFormAbility'
const DOMAIN_NUMBER = 0xFF00

/**
 * 桌面卡片FormAbility
 * 处理卡片的创建、更新、销毁等生命周期事件
 */
export default class EntryFormAbility extends FormExtensionAbility {
  private widgetService = WidgetService.getInstance()
  
  /**
   * 卡片创建时调用
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN_NUMBER, TAG, 'onAddForm called')
    
    try {
      const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string
      
      if (formId) {
        // 异步更新卡片数据
        this.updateFormData(formId)
      }
      
      const formData: FormData = {
        todayIncome: '0.00',
        todayExpense: '0.00',
        monthIncome: '0.00',
        monthExpense: '0.00',
        totalBalance: '0.00',
        recentBills: [],
        lastUpdateTime: new Date().toLocaleTimeString()
      }
      
      return formBindingData.createFormBindingData(formData)
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `onAddForm error: ${error}`)
      const defaultData: FormData = {
        todayIncome: '0.00',
        todayExpense: '0.00',
        monthIncome: '0.00',
        monthExpense: '0.00',
        totalBalance: '0.00',
        recentBills: [],
        lastUpdateTime: new Date().toLocaleTimeString()
      }
      return formBindingData.createFormBindingData(defaultData)
    }
  }
  
  /**
   * 卡片可见性变化时调用
   */
  onVisibilityChange(newStatus: Record<string, number>): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onVisibilityChange newStatus: ${JSON.stringify(newStatus)}`)
    
    try {
      // 遍历所有表单的可见性状态
      const formIds = Object.keys(newStatus)
      for (let i = 0; i < formIds.length; i++) {
        const formId = formIds[i]
        const isVisible = newStatus[formId] === 1
        
        if (isVisible) {
          // 表单变为可见时，更新数据
          this.updateFormData(formId)
        }
      }
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `onVisibilityChange error: ${error}`)
    }
  }
  
  /**
   * 卡片事件处理
   */
  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onFormEvent formId: ${formId}, message: ${message}`)
    
    try {
      const eventData = JSON.parse(message) as Record<string, Object>
      
      // 直接处理事件数据
      const action = eventData.action as string
      const params = eventData.params as Record<string, Object>
      
      if (action === 'quickExpense') {
        this.handleQuickExpense(params)
      } else if (action === 'quickIncome') {
        this.handleQuickIncome(params)
      }
      
      // 更新表单数据
      this.updateFormData(formId)
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `onFormEvent error: ${error}`)
    }
  }
  
  private async handleQuickExpense(params: Record<string, Object>): Promise<void> {
    try {
      await this.widgetService.quickAddExpense(
        (params.amount as number) || 0,
        (params.category as string) || '其他'
      )
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `handleQuickExpense error: ${error}`)
    }
  }
  
  private async handleQuickIncome(params: Record<string, Object>): Promise<void> {
    try {
      await this.widgetService.quickAddIncome(
        (params.amount as number) || 0,
        (params.category as string) || '其他'
      )
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `handleQuickIncome error: ${error}`)
    }
  }
  
  /**
   * 卡片删除时调用
   */
  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRemoveForm called, formId: ${formId}`)
    
    try {
      // 清理卡片相关资源
      // 这里可以添加清理逻辑，比如取消定时器等
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `onRemoveForm error: ${error}`)
    }
  }
  
  /**
   * 卡片配置更新时调用
   */
  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onConfigurationUpdate called')
    
    try {
      // 处理配置更新，比如主题变化等
      // 可以根据新配置重新渲染卡片
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `onConfigurationUpdate error: ${error}`)
    }
  }
  
  /**
   * 获取卡片信息时调用
   */
  onAcquireFormState(want: Want): formInfo.FormState {
    hilog.info(DOMAIN_NUMBER, TAG, 'onAcquireFormState called')
    
    try {
      return formInfo.FormState.READY
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `onAcquireFormState error: ${error}`)
      return formInfo.FormState.DEFAULT
    }
  }
  
  /**
   * 更新卡片数据
   */
  private async updateFormData(formId: string): Promise<void> {
    try {
      const widgetData = await this.widgetService.getWidgetData()
      
      const formData: FormData = {
        todayIncome: widgetData.todayIncome.toFixed(2),
        todayExpense: widgetData.todayExpense.toFixed(2),
        monthIncome: widgetData.monthIncome.toFixed(2),
        monthExpense: widgetData.monthExpense.toFixed(2),
        totalBalance: widgetData.totalBalance.toFixed(2),
        recentBills: widgetData.recentBills.slice(0, 3),
        lastUpdateTime: new Date().toLocaleTimeString()
      }
      
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData))
      hilog.info(DOMAIN_NUMBER, TAG, `Form data updated for formId: ${formId}`)
    } catch (error) {
      hilog.error(DOMAIN_NUMBER, TAG, `Failed to update form data: ${error}`)
    }
  }
}