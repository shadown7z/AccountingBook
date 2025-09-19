/**
 * 页面路径常量
 */
export class PagePath {
  static readonly INDEX = 'pages/Index'
  static readonly ADD_RECORD = 'pages/AddRecordPage'
  static readonly BILL_LIST = 'pages/BillListPage'
  static readonly ACCOUNT_MANAGE = 'pages/AccountManagePage'
  static readonly BUDGET_SETTING = 'pages/BudgetSettingPage'
  static readonly STATISTICS = 'pages/StatisticsPage'
  static readonly BACKUP = 'pages/BackupPage'
  static readonly CATEGORY_MANAGE = 'pages/CategoryManagePage'
  static readonly EXPORT = 'pages/ExportPage'
  static readonly REMINDER = 'pages/ReminderPage'
  static readonly QRCODE = 'pages/QRCodePage'
}

// 兼容旧的PAGE_PATH常量
export class PAGE_PATH {
  static readonly STATISTICS = PagePath.STATISTICS
  static readonly BACKUP = PagePath.BACKUP
  static readonly EXPORT = PagePath.EXPORT
  static readonly REMINDER = PagePath.REMINDER
}