// 账单记录数据模型
@ObservedV2
export class BillRecord {
  @Trace id: number = 0
  @Trace amount: number = 0
  @Trace type: BillType = BillType.EXPENSE
  @Trace category: string = ''
  @Trace note: string = ''
  @Trace date: string = ''
  @Trace createTime: string = ''
  @Trace accountId: number = 0  // 关联的账户ID

  constructor(amount: number = 0, type: BillType = BillType.EXPENSE, category: string = '', note: string = '', accountId: number = 0) {
    this.amount = amount
    this.type = type
    this.category = category
    this.note = note
    this.date = new Date().toISOString().split('T')[0]
    this.createTime = new Date().toISOString()
    this.accountId = accountId
  }
}

// 账单类型枚举
export enum BillType {
  INCOME = 'income',
  EXPENSE = 'expense'
}

// 账单分类数据模型
@ObservedV2
export class BillCategory {
  @Trace id: number = 0
  @Trace name: string = ''
  @Trace icon: string = ''
  @Trace color: string = '#FF6B6B' // 默认颜色
  @Trace type: BillType = BillType.EXPENSE
  @Trace isDefault: boolean = false

  constructor(name: string, icon: string, type: BillType, isDefault: boolean = false, color: string = '#FF6B6B') {
    this.name = name
    this.icon = icon
    this.type = type
    this.isDefault = isDefault
    this.color = color
  }
}

// 统计数据模型
@ObservedV2
export class BillStatistics {
  @Trace totalIncome: number = 0
  @Trace totalExpense: number = 0
  @Trace balance: number = 0
  @Trace monthlyIncome: number = 0
  @Trace monthlyExpense: number = 0

  constructor() {
    this.updateBalance()
  }

  updateBalance() {
    this.balance = this.totalIncome - this.totalExpense
  }
}