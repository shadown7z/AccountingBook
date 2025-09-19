/**
 * 预算数据模型
 */

// 预算类型枚举
export enum BudgetType {
  MONTHLY = 'monthly',    // 月度预算
  CATEGORY = 'category'   // 分类预算
}

// 预算状态枚举
export enum BudgetStatus {
  NORMAL = 'normal',      // 正常
  WARNING = 'warning',    // 警告（超过80%）
  EXCEEDED = 'exceeded'   // 超支
}

// 预算信息类
export class Budget {
  id: number
  type: BudgetType
  name: string
  amount: number
  spent: number
  category?: string       // 分类预算时的分类名称
  year: number
  month: number
  isActive: boolean
  createdAt: Date
  updatedAt: Date

  constructor(
    id: number = 0,
    type: BudgetType = BudgetType.MONTHLY,
    name: string = '',
    amount: number = 0,
    spent: number = 0,
    category?: string,
    year: number = new Date().getFullYear(),
    month: number = new Date().getMonth() + 1,
    isActive: boolean = true,
    createdAt: Date = new Date(),
    updatedAt: Date = new Date()
  ) {
    this.id = id
    this.type = type
    this.name = name
    this.amount = amount
    this.spent = spent
    this.category = category
    this.year = year
    this.month = month
    this.isActive = isActive
    this.createdAt = createdAt
    this.updatedAt = updatedAt
  }

  // 获取剩余预算
  getRemainingAmount(): number {
    return Math.max(0, this.amount - this.spent)
  }

  // 获取使用百分比
  getUsagePercentage(): number {
    if (this.amount === 0) return 0
    return Math.min(100, (this.spent / this.amount) * 100)
  }

  // 获取预算状态
  getStatus(): BudgetStatus {
    const percentage = this.getUsagePercentage()
    if (percentage >= 100) {
      return BudgetStatus.EXCEEDED
    } else if (percentage >= 80) {
      return BudgetStatus.WARNING
    } else {
      return BudgetStatus.NORMAL
    }
  }

  // 获取状态颜色
  getStatusColor(): string {
    switch (this.getStatus()) {
      case BudgetStatus.EXCEEDED:
        return '#FF4444'
      case BudgetStatus.WARNING:
        return '#FF8800'
      default:
        return '#4CAF50'
    }
  }

  // 获取状态文本
  getStatusText(): string {
    switch (this.getStatus()) {
      case BudgetStatus.EXCEEDED:
        return '已超支'
      case BudgetStatus.WARNING:
        return '接近预算'
      default:
        return '正常'
    }
  }

  // 更新已花费金额
  updateSpent(amount: number): void {
    this.spent = Math.max(0, amount)
    this.updatedAt = new Date()
  }

  // 添加支出
  addExpense(amount: number): void {
    this.spent += amount
    this.updatedAt = new Date()
  }

  // 减少支出（退款等）
  reduceExpense(amount: number): void {
    this.spent = Math.max(0, this.spent - amount)
    this.updatedAt = new Date()
  }

  // 检查是否为当前月份
  isCurrentMonth(): boolean {
    const now = new Date()
    return this.year === now.getFullYear() && this.month === (now.getMonth() + 1)
  }

  // 获取预算期间描述
  getPeriodDescription(): string {
    return `${this.year}年${this.month}月`
  }
}

// 预算统计信息类
export class BudgetStatistics {
  totalBudget: number = 0
  totalSpent: number = 0
  activeBudgets: number = 0
  exceededBudgets: number = 0
  warningBudgets: number = 0

  constructor(
    totalBudget: number = 0,
    totalSpent: number = 0,
    activeBudgets: number = 0,
    exceededBudgets: number = 0,
    warningBudgets: number = 0
  ) {
    this.totalBudget = totalBudget
    this.totalSpent = totalSpent
    this.activeBudgets = activeBudgets
    this.exceededBudgets = exceededBudgets
    this.warningBudgets = warningBudgets
  }

  // 获取总剩余预算
  getTotalRemaining(): number {
    return Math.max(0, this.totalBudget - this.totalSpent)
  }

  // 获取总使用百分比
  getTotalUsagePercentage(): number {
    if (this.totalBudget === 0) return 0
    return Math.min(100, (this.totalSpent / this.totalBudget) * 100)
  }

  // 获取健康状态
  getHealthStatus(): BudgetStatus {
    const percentage = this.getTotalUsagePercentage()
    if (percentage >= 100) {
      return BudgetStatus.EXCEEDED
    } else if (percentage >= 80) {
      return BudgetStatus.WARNING
    } else {
      return BudgetStatus.NORMAL
    }
  }
}