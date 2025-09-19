/**
 * 预算管理服务
 */

import { relationalStore } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { Budget, BudgetType, BudgetStatistics } from '../model/Budget'
import { BillService } from './BillService'
import { BillType } from '../model/BillRecord'

export class BudgetService {
  private static instance: BudgetService
  private rdbStore: relationalStore.RdbStore | null = null
  private context: common.UIAbilityContext | null = null
  private budgets: Budget[] = []

  private constructor() {}

  static getInstance(): BudgetService {
    if (!BudgetService.instance) {
      BudgetService.instance = new BudgetService()
    }
    return BudgetService.instance
  }

  // 初始化数据库
  async initDatabase(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'budgets.db',
      securityLevel: relationalStore.SecurityLevel.S3
    }

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
      await this.createTables()
      await this.loadBudgets()
    } catch (error) {
      console.error('预算数据库初始化失败:', error)
    }
  }

  // 创建数据表
  private async createTables(): Promise<void> {
    if (!this.rdbStore) return

    const createBudgetTable = `
      CREATE TABLE IF NOT EXISTS budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        spent REAL DEFAULT 0,
        category TEXT,
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    `

    try {
      await this.rdbStore.executeSql(createBudgetTable)
    } catch (error) {
      console.error('创建预算表失败:', error)
    }
  }

  // 加载预算数据
  private async loadBudgets(): Promise<void> {
    if (!this.rdbStore) return

    try {
      const resultSet = await this.rdbStore.querySql('SELECT * FROM budgets ORDER BY created_at DESC')
      this.budgets = []

      if (resultSet.goToFirstRow()) {
        do {
          const budget = new Budget(
            resultSet.getLong(resultSet.getColumnIndex('id')),
            resultSet.getString(resultSet.getColumnIndex('type')) as BudgetType,
            resultSet.getString(resultSet.getColumnIndex('name')),
            resultSet.getDouble(resultSet.getColumnIndex('amount')),
            resultSet.getDouble(resultSet.getColumnIndex('spent')),
            resultSet.getString(resultSet.getColumnIndex('category')) || undefined,
            resultSet.getLong(resultSet.getColumnIndex('year')),
            resultSet.getLong(resultSet.getColumnIndex('month')),
            resultSet.getLong(resultSet.getColumnIndex('is_active')) === 1,
            new Date(resultSet.getString(resultSet.getColumnIndex('created_at'))),
            new Date(resultSet.getString(resultSet.getColumnIndex('updated_at')))
          )
          this.budgets.push(budget)
        } while (resultSet.goToNextRow())
      }
      resultSet.close()
    } catch (error) {
      console.error('加载预算数据失败:', error)
    }
  }

  // 添加预算
  async addBudget(budget: Budget): Promise<boolean> {
    if (!this.rdbStore) return false

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        type: budget.type,
        name: budget.name,
        amount: budget.amount,
        spent: budget.spent,
        category: budget.category || null,
        year: budget.year,
        month: budget.month,
        is_active: budget.isActive ? 1 : 0,
        created_at: budget.createdAt.toISOString(),
        updated_at: budget.updatedAt.toISOString()
      }

      const rowId = await this.rdbStore.insert('budgets', valueBucket)
      budget.id = rowId
      this.budgets.unshift(budget)
      
      // 更新预算支出金额
      await this.updateBudgetSpent(budget)
      
      return true
    } catch (error) {
      console.error('添加预算失败:', error)
      return false
    }
  }

  // 更新预算
  async updateBudget(budget: Budget): Promise<boolean> {
    if (!this.rdbStore) return false

    try {
      const valueBucket: relationalStore.ValuesBucket = {
        type: budget.type,
        name: budget.name,
        amount: budget.amount,
        spent: budget.spent,
        category: budget.category || null,
        year: budget.year,
        month: budget.month,
        is_active: budget.isActive ? 1 : 0,
        updated_at: new Date().toISOString()
      }

      const predicates = new relationalStore.RdbPredicates('budgets')
      predicates.equalTo('id', budget.id)
      
      await this.rdbStore.update(valueBucket, predicates)
      
      // 更新内存中的数据
      const index = this.budgets.findIndex(b => b.id === budget.id)
      if (index !== -1) {
        this.budgets[index] = budget
      }
      
      return true
    } catch (error) {
      console.error('更新预算失败:', error)
      return false
    }
  }

  // 删除预算
  async deleteBudget(budgetId: number): Promise<boolean> {
    if (!this.rdbStore) return false

    try {
      const predicates = new relationalStore.RdbPredicates('budgets')
      predicates.equalTo('id', budgetId)
      
      await this.rdbStore.delete(predicates)
      
      // 从内存中移除
      this.budgets = this.budgets.filter(budget => budget.id !== budgetId)
      
      return true
    } catch (error) {
      console.error('删除预算失败:', error)
      return false
    }
  }

  // 获取所有预算
  async getAllBudgets(): Promise<Budget[]> {
    await this.loadBudgets()
    return [...this.budgets]
  }

  // 获取当前月份预算
  async getCurrentMonthBudgets(): Promise<Budget[]> {
    const now = new Date()
    const currentYear = now.getFullYear()
    const currentMonth = now.getMonth() + 1
    
    return this.budgets.filter(budget => 
      budget.year === currentYear && 
      budget.month === currentMonth && 
      budget.isActive
    )
  }

  // 获取分类预算
  async getCategoryBudgets(year: number, month: number): Promise<Budget[]> {
    return this.budgets.filter(budget => 
      budget.type === BudgetType.CATEGORY &&
      budget.year === year && 
      budget.month === month && 
      budget.isActive
    )
  }

  // 获取月度总预算
  async getMonthlyBudget(year: number, month: number): Promise<Budget | null> {
    const monthlyBudget = this.budgets.find(budget => 
      budget.type === BudgetType.MONTHLY &&
      budget.year === year && 
      budget.month === month && 
      budget.isActive
    )
    return monthlyBudget || null
  }

  // 更新预算支出金额
  async updateBudgetSpent(budget: Budget): Promise<void> {
    const billService = BillService.getInstance()
    
    try {
      if (budget.type === BudgetType.MONTHLY) {
        // 月度预算：计算当月所有支出
        const monthlyExpense = await billService.getMonthlyExpense(budget.year, budget.month)
        budget.updateSpent(monthlyExpense)
      } else if (budget.type === BudgetType.CATEGORY && budget.category) {
        // 分类预算：计算当月该分类的支出
        const categoryExpense = await billService.getCategoryExpense(budget.category, budget.year, budget.month)
        budget.updateSpent(categoryExpense)
      }
      
      // 更新数据库
      await this.updateBudget(budget)
    } catch (error) {
      console.error('更新预算支出失败:', error)
    }
  }

  // 更新所有预算的支出金额
  async updateAllBudgetsSpent(): Promise<void> {
    for (const budget of this.budgets) {
      if (budget.isActive) {
        await this.updateBudgetSpent(budget)
      }
    }
  }

  // 获取预算统计信息
  async getBudgetStatistics(year: number, month: number): Promise<BudgetStatistics> {
    const budgets = this.budgets.filter(budget => 
      budget.year === year && 
      budget.month === month && 
      budget.isActive
    )

    const totalBudget = budgets.reduce((sum, budget) => sum + budget.amount, 0)
    const totalSpent = budgets.reduce((sum, budget) => sum + budget.spent, 0)
    const activeBudgets = budgets.length
    const exceededBudgets = budgets.filter(budget => budget.spent > budget.amount).length
    const warningBudgets = budgets.filter(budget => {
      const percentage = budget.getUsagePercentage()
      return percentage >= 80 && percentage < 100
    }).length

    return new BudgetStatistics(
      totalBudget,
      totalSpent,
      activeBudgets,
      exceededBudgets,
      warningBudgets
    )
  }

  // 检查预算警告
  async checkBudgetWarnings(): Promise<Budget[]> {
    const now = new Date()
    const currentBudgets = await this.getCurrentMonthBudgets()
    
    return currentBudgets.filter(budget => {
      const percentage = budget.getUsagePercentage()
      return percentage >= 80 // 超过80%的预算
    })
  }

  // 获取预算建议
  async getBudgetSuggestions(): Promise<string[]> {
    const suggestions: string[] = []
    const currentBudgets = await this.getCurrentMonthBudgets()
    
    if (currentBudgets.length === 0) {
      suggestions.push('建议设置月度预算，帮助控制支出')
    }
    
    const exceededBudgets = currentBudgets.filter(budget => budget.spent > budget.amount)
    if (exceededBudgets.length > 0) {
      suggestions.push(`有${exceededBudgets.length}个预算已超支，建议调整支出计划`)
    }
    
    const warningBudgets = currentBudgets.filter(budget => {
      const percentage = budget.getUsagePercentage()
      return percentage >= 80 && percentage < 100
    })
    if (warningBudgets.length > 0) {
      suggestions.push(`有${warningBudgets.length}个预算接近上限，请注意控制支出`)
    }
    
    return suggestions
  }
}