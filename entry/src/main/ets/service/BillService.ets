// 账单数据管理服务
import { relationalStore } from '@kit.ArkData'
import { BillRecord, BillType, BillCategory, BillStatistics } from '../model/BillRecord'
import { AccountService } from './AccountService'
import { common } from '@kit.AbilityKit'

@ObservedV2
export class BillService {
  private static instance: BillService
  private rdbStore: relationalStore.RdbStore | null = null
  private context: common.UIAbilityContext | null = null
  private billRecords: BillRecord[] = []
  private categories: BillCategory[] = []
  @Trace private statistics: BillStatistics = new BillStatistics()

  private constructor() {
    this.initDefaultCategories()
  }

  static getInstance(): BillService {
    if (!BillService.instance) {
      BillService.instance = new BillService()
    }
    return BillService.instance
  }

  // 初始化数据库
  async initDatabase(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'bills.db',
      securityLevel: relationalStore.SecurityLevel.S3
    }

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
      await this.createTables()
      await this.loadData()
      // 初始化账户服务
      await AccountService.getInstance().initDatabase(context)
    } catch (error) {
      console.error('数据库初始化失败:', error)
    }
  }

  // 创建数据表
  private async createTables() {
    if (!this.rdbStore) return

    // 创建账单记录表
    const createBillTable = `
      CREATE TABLE IF NOT EXISTS bill_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        create_time TEXT NOT NULL,
        account_id INTEGER DEFAULT 0
      )
    `

    // 创建分类表
    const createCategoryTable = `
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT DEFAULT '#FF6B6B',
        type TEXT NOT NULL,
        is_default INTEGER DEFAULT 0
      )
    `

    await this.rdbStore.executeSql(createBillTable)
    await this.rdbStore.executeSql(createCategoryTable)
  }

  // 初始化默认分类
  private initDefaultCategories() {
    // 支出分类
    this.categories = [
      new BillCategory('餐饮', '🍽️', BillType.EXPENSE, true, '#FF6B6B'),
      new BillCategory('交通', '🚗', BillType.EXPENSE, true, '#4ECDC4'),
      new BillCategory('购物', '🛒', BillType.EXPENSE, true, '#45B7D1'),
      new BillCategory('娱乐', '🎮', BillType.EXPENSE, true, '#96CEB4'),
      new BillCategory('医疗', '🏥', BillType.EXPENSE, true, '#FFEAA7'),
      new BillCategory('教育', '📚', BillType.EXPENSE, true, '#DDA0DD'),
      new BillCategory('住房', '🏠', BillType.EXPENSE, true, '#98D8C8'),
      new BillCategory('其他', '📝', BillType.EXPENSE, true, '#F7DC6F'),
      // 收入分类
      new BillCategory('工资', '💰', BillType.INCOME, true, '#58D68D'),
      new BillCategory('奖金', '🎁', BillType.INCOME, true, '#F8C471'),
      new BillCategory('投资', '📈', BillType.INCOME, true, '#85C1E9'),
      new BillCategory('兼职', '💼', BillType.INCOME, true, '#BB8FCE'),
      new BillCategory('其他', '📝', BillType.INCOME, true, '#82E0AA')
    ]
  }

  // 加载数据
  private async loadData() {
    await this.loadCategories()
    await this.loadBillRecords()
    this.updateStatistics()
  }

  // 加载账单记录
  private async loadBillRecords() {
    if (!this.rdbStore) return

    try {
      const resultSet = await this.rdbStore.querySql('SELECT * FROM bill_records ORDER BY create_time DESC')
      this.billRecords = []
      
      while (resultSet.goToNextRow()) {
        const record = new BillRecord()
        record.id = resultSet.getLong(resultSet.getColumnIndex('id'))
        record.amount = resultSet.getDouble(resultSet.getColumnIndex('amount'))
        record.type = resultSet.getString(resultSet.getColumnIndex('type')) as BillType
        record.category = resultSet.getString(resultSet.getColumnIndex('category'))
        record.note = resultSet.getString(resultSet.getColumnIndex('note'))
        record.date = resultSet.getString(resultSet.getColumnIndex('date'))
        record.createTime = resultSet.getString(resultSet.getColumnIndex('create_time'))
        record.accountId = resultSet.getLong(resultSet.getColumnIndex('account_id'))
        this.billRecords.push(record)
      }
      resultSet.close()
    } catch (error) {
      console.error('加载账单记录失败:', error)
    }
  }

  // 添加账单记录
  async addBillRecord(record: BillRecord): Promise<boolean> {
    if (!this.rdbStore) return false

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        amount: record.amount,
        type: record.type,
        category: record.category,
        note: record.note,
        date: record.date,
        create_time: record.createTime,
        account_id: record.accountId
      }

      const rowId = await this.rdbStore.insert('bill_records', valueBucket)
      record.id = rowId
      this.billRecords.unshift(record)
      this.updateStatistics()
      
      // 更新账户余额
      const amount = record.type === BillType.INCOME ? record.amount : -record.amount
      await AccountService.getInstance().updateAccountBalance(record.accountId, amount)
      
      // 触发桌面卡片数据同步更新
      await this.notifyWidgetUpdate()
      
      console.info('账单记录添加成功，已触发桌面卡片更新')
      return true
    } catch (error) {
      console.error('添加账单记录失败:', error)
      return false
    }
  }

  // 获取账单记录列表
  getBillRecords(): BillRecord[] {
    return this.billRecords
  }

  // 获取最近的账单记录
  getRecentBillRecords(limit: number = 5): BillRecord[] {
    return this.billRecords.slice(0, limit)
  }

  // 获取分类列表
  getCategories(type?: BillType): BillCategory[] {
    if (type) {
      return this.categories.filter(category => category.type === type)
    }
    return this.categories
  }

  // 获取所有分类名称
  async getAllCategories(): Promise<string[]> {
    const categories = this.getCategories()
    return categories.map(category => category.name)
  }

  // 加载分类数据
  private async loadCategories() {
    if (!this.rdbStore) return

    try {
      const resultSet = await this.rdbStore.querySql('SELECT * FROM categories ORDER BY type, name')
      const loadedCategories: BillCategory[] = []
      
      while (resultSet.goToNextRow()) {
        const category = new BillCategory('', '', BillType.EXPENSE)
        category.id = resultSet.getLong(resultSet.getColumnIndex('id'))
        category.name = resultSet.getString(resultSet.getColumnIndex('name'))
        category.icon = resultSet.getString(resultSet.getColumnIndex('icon'))
        category.color = resultSet.getString(resultSet.getColumnIndex('color')) || '#FF6B6B'
        category.type = resultSet.getString(resultSet.getColumnIndex('type')) as BillType
        category.isDefault = resultSet.getLong(resultSet.getColumnIndex('is_default')) === 1
        loadedCategories.push(category)
      }
      resultSet.close()
      
      // 如果数据库中没有分类，则插入默认分类
      if (loadedCategories.length === 0) {
        await this.insertDefaultCategories()
      } else {
        this.categories = loadedCategories
      }
    } catch (error) {
      console.error('加载分类数据失败:', error)
      // 如果加载失败，使用默认分类
      await this.insertDefaultCategories()
    }
  }

  // 插入默认分类到数据库
  private async insertDefaultCategories() {
    if (!this.rdbStore) return

    try {
      for (const category of this.categories) {
        const valueBucket: relationalStore.ValuesBucket = {
          name: category.name,
          icon: category.icon,
          color: category.color,
          type: category.type,
          is_default: category.isDefault ? 1 : 0
        }
        const rowId = await this.rdbStore.insert('categories', valueBucket)
        category.id = rowId
      }
    } catch (error) {
      console.error('插入默认分类失败:', error)
    }
  }

  // 添加自定义分类
  async addCategory(category: BillCategory): Promise<boolean> {
    if (!this.rdbStore) return false

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        name: category.name,
        icon: category.icon,
        color: category.color,
        type: category.type,
        is_default: 0
      }
      
      const rowId = await this.rdbStore.insert('categories', valueBucket)
      category.id = rowId
      this.categories.push(category)
      return true
    } catch (error) {
      console.error('添加分类失败:', error)
      return false
    }
  }

  // 更新分类
  async updateCategory(category: BillCategory): Promise<boolean> {
    if (!this.rdbStore || category.id === 0) return false

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        name: category.name,
        icon: category.icon,
        color: category.color,
        type: category.type
      }
      
      const predicates = new relationalStore.RdbPredicates('categories')
      predicates.equalTo('id', category.id)
      
      const rowsAffected = await this.rdbStore.update(valueBucket, predicates)
      if (rowsAffected > 0) {
        // 更新内存中的分类
        const index = this.categories.findIndex(c => c.id === category.id)
        if (index !== -1) {
          this.categories[index] = category
        }
        return true
      }
      return false
    } catch (error) {
      console.error('更新分类失败:', error)
      return false
    }
  }

  // 删除分类
  async deleteCategory(categoryId: number): Promise<boolean> {
    if (!this.rdbStore || categoryId === 0) return false

    try {
      // 检查是否为默认分类
      const category = this.categories.find(c => c.id === categoryId)
      if (category?.isDefault) {
        console.warn('不能删除默认分类')
        return false
      }

      // 检查是否有关联的账单记录
      const hasRecords = this.billRecords.some(record => {
        const recordCategory = this.categories.find(c => c.name === record.category)
        return recordCategory?.id === categoryId
      })
      
      if (hasRecords) {
        console.warn('该分类下有账单记录，不能删除')
        return false
      }

      const predicates = new relationalStore.RdbPredicates('categories')
      predicates.equalTo('id', categoryId)
      
      const rowsAffected = await this.rdbStore.delete(predicates)
      if (rowsAffected > 0) {
        // 从内存中移除分类
        this.categories = this.categories.filter(c => c.id !== categoryId)
        return true
      }
      return false
    } catch (error) {
      console.error('删除分类失败:', error)
      return false
    }
  }

  // 获取月度支出总额
  async getMonthlyExpense(year: number, month: number): Promise<number> {
    const records = this.billRecords.filter(record => {
      const recordDate = new Date(record.date)
      return record.type === BillType.EXPENSE &&
             recordDate.getFullYear() === year &&
             recordDate.getMonth() + 1 === month
    })
    return records.reduce((sum, record) => sum + record.amount, 0)
  }

  // 获取分类支出金额
  async getCategoryExpense(category: string, year: number, month: number): Promise<number> {
    const records = this.billRecords.filter(record => {
      const recordDate = new Date(record.date)
      return record.type === BillType.EXPENSE &&
             record.category === category &&
             recordDate.getFullYear() === year &&
             recordDate.getMonth() + 1 === month
    })
    return records.reduce((sum, record) => sum + record.amount, 0)
  }

  // 获取统计数据
  getStatistics(): BillStatistics {
    return this.statistics
  }

  // 更新统计数据
  private updateStatistics() {
    const currentMonth = new Date().toISOString().slice(0, 7) // YYYY-MM
    
    this.statistics.totalIncome = this.billRecords
      .filter(record => record.type === BillType.INCOME)
      .reduce((sum, record) => sum + record.amount, 0)
    
    this.statistics.totalExpense = this.billRecords
      .filter(record => record.type === BillType.EXPENSE)
      .reduce((sum, record) => sum + record.amount, 0)
    
    this.statistics.monthlyIncome = this.billRecords
      .filter(record => record.type === BillType.INCOME && record.date.startsWith(currentMonth))
      .reduce((sum, record) => sum + record.amount, 0)
    
    this.statistics.monthlyExpense = this.billRecords
      .filter(record => record.type === BillType.EXPENSE && record.date.startsWith(currentMonth))
      .reduce((sum, record) => sum + record.amount, 0)
    
    this.statistics.updateBalance()
  }

  // 格式化金额显示
  static formatAmount(amount: number): string {
    return amount.toFixed(2)
  }

  // 通知桌面卡片更新
  private async notifyWidgetUpdate(): Promise<void> {
    try {
      // 导入WidgetService并触发更新
      const widgetServiceModule = await import('../service/WidgetService')
      const widgetService = widgetServiceModule.WidgetService.getInstance()
      
      // 更新所有活跃的桌面卡片
      await widgetService.updateAllActiveWidgets()
      
      console.info('桌面卡片数据同步更新完成')
    } catch (error) {
      console.error('桌面卡片更新失败:', error)
    }
  }
}