/**
 * 账户数据模型
 */

// 账户类型枚举
export enum AccountType {
  CASH = 'cash',           // 现金
  ALIPAY = 'alipay',       // 支付宝
  WECHAT = 'wechat',       // 微信钱包
  BANK_CARD = 'bank_card', // 银行卡
  CREDIT_CARD = 'credit_card', // 信用卡
  OTHER = 'other'          // 其他
}

// 账户信息类
export class Account {
  id: number = 0
  name: string = ''
  type: AccountType = AccountType.CASH
  balance: number = 0
  initialBalance: number = 0
  icon: string = ''
  color: string = ''
  isDefault: boolean = false
  createTime: Date = new Date()
  updateTime: Date = new Date()

  constructor(
    name: string = '',
    type: AccountType = AccountType.CASH,
    initialBalance: number = 0,
    icon: string = '',
    color: string = ''
  ) {
    this.name = name
    this.type = type
    this.balance = initialBalance
    this.initialBalance = initialBalance
    this.icon = icon
    this.color = color
    this.createTime = new Date()
    this.updateTime = new Date()
  }

  // 更新余额
  updateBalance(amount: number): void {
    this.balance += amount
    this.updateTime = new Date()
  }

  // 获取账户类型显示名称
  getTypeDisplayName(): string {
    switch (this.type) {
      case AccountType.CASH:
        return '现金'
      case AccountType.ALIPAY:
        return '支付宝'
      case AccountType.WECHAT:
        return '微信钱包'
      case AccountType.BANK_CARD:
        return '银行卡'
      case AccountType.CREDIT_CARD:
        return '信用卡'
      case AccountType.OTHER:
        return '其他'
      default:
        return '未知'
    }
  }

  // 获取默认图标
  getDefaultIcon(): string {
    switch (this.type) {
      case AccountType.CASH:
        return '💰'
      case AccountType.ALIPAY:
        return '🔵'
      case AccountType.WECHAT:
        return '🟢'
      case AccountType.BANK_CARD:
        return '🏦'
      case AccountType.CREDIT_CARD:
        return '💳'
      case AccountType.OTHER:
        return '📱'
      default:
        return '💰'
    }
  }

  // 获取默认颜色
  getDefaultColor(): string {
    switch (this.type) {
      case AccountType.CASH:
        return '#4CAF50'
      case AccountType.ALIPAY:
        return '#1677FF'
      case AccountType.WECHAT:
        return '#07C160'
      case AccountType.BANK_CARD:
        return '#FF9800'
      case AccountType.CREDIT_CARD:
        return '#9C27B0'
      case AccountType.OTHER:
        return '#607D8B'
      default:
        return '#4CAF50'
    }
  }
}

// 账户统计信息
export class AccountStatistics {
  totalBalance: number = 0
  totalIncome: number = 0
  totalExpense: number = 0
  accountCount: number = 0

  constructor(
    totalBalance: number = 0,
    totalIncome: number = 0,
    totalExpense: number = 0,
    accountCount: number = 0
  ) {
    this.totalBalance = totalBalance
    this.totalIncome = totalIncome
    this.totalExpense = totalExpense
    this.accountCount = accountCount
  }
}