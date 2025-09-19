import { BillService } from '../service/BillService'
import { BillRecord, BillType, BillStatistics } from '../model/BillRecord'
import { AccountService } from '../service/AccountService'
import { Account } from '../model/Account'
import { BudgetService } from '../service/BudgetService'
import { Budget, BudgetStatistics } from '../model/Budget'
import { PagePath } from '../constants/PagePath'
import { router } from '@kit.ArkUI'
import { HMRouterMgr } from '@hadss/hmrouter'

@Entry
@ComponentV2
struct Index {
  @Local billService: BillService = BillService.getInstance()
  @Local statistics: BillStatistics = new BillStatistics()
  @Local recentRecords: BillRecord[] = []
  @Local accounts: Account[] = []
  @Local totalBalance: number = 0
  @Local budgetStatistics: BudgetStatistics = new BudgetStatistics()
  @Local currentBudgets: Budget[] = []
  private accountService = AccountService.getInstance()
  private budgetService = BudgetService.getInstance()

  aboutToAppear() {
    this.loadData()
  }

  onPageShow() {
    // 页面显示时刷新数据
    this.loadData()
  }

  private async loadData(): Promise<void> {
    this.statistics = await this.billService.getStatistics()
    this.recentRecords = await this.billService.getRecentBillRecords(5)
    this.accounts = await this.accountService.getAllAccounts()
    this.calculateTotalBalance()
    
    // 加载预算数据
    const now = new Date()
    this.budgetStatistics = await this.budgetService.getBudgetStatistics(now.getFullYear(), now.getMonth() + 1)
    this.currentBudgets = await this.budgetService.getCurrentMonthBudgets()
  }

  // 计算总余额
  private calculateTotalBalance(): void {
    this.totalBalance = this.accounts.reduce((sum, account) => sum + account.balance, 0)
  }

  build() {
    Column() {
      // 顶部标题栏
      this.buildHeader()
      
      // 滚动内容区域
      Scroll() {
        Column({ space: 16 }) {
          // 收支概览卡片
          this.buildOverviewCard()
          
          // 账户概览
          this.buildAccountSection()
          
          // 预算概览
          this.buildBudgetSection()
          
          // 快速记账按钮
          this.buildQuickActionButton()
          
          // 数据统计入口
          this.buildStatisticsEntry()
          
          // 分类管理入口
          this.buildCategoryManageEntry()
          
          // 数据备份入口
          this.buildBackupEntry()
          
          // 桌面卡片入口
          this.buildWidgetEntry()
          
          // 提醒设置入口
          this.buildReminderEntry()
          
          // 反馈中心入口
          this.buildFeedbackEntry()
          
          // 最近记录
          this.buildRecentRecords()
        }
        .padding({ left: 16, right: 16, bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }

  // 构建顶部标题栏
  @Builder
  buildHeader() {
    Row() {
      Text($r('app.string.home_title'))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
      
      // 导出按钮
      // Button('导出')
      //   .type(ButtonType.Normal)
      //   .backgroundColor($r('app.color.primary_color'))
      //   .fontColor(Color.White)
      //   .borderRadius(8)
      //   .fontSize(14)
      //   .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      //   .onClick(() => {
      //     router.pushUrl({
      //       url: 'pages/ExportPage'
      //     })
      //   })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.primary_color'))
  }

  // 构建收支概览卡片
  @Builder
  buildOverviewCard() {
    Column({ space: 16 }) {
      // 总余额
      Column({ space: 4 }) {
        Text($r('app.string.total_balance'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        
        Text(`¥${BillService.formatAmount(this.statistics.balance)}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .alignItems(HorizontalAlign.Center)
      
      // 本月收支
      Row() {
        // 总资产
        Column({ space: 4 }) {
          Text('总资产')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          
          Text(`¥${BillService.formatAmount(this.totalBalance)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary_color'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        // 分割线
        Divider()
          .vertical(true)
          .height(40)
          .color($r('app.color.divider_color'))
        
        // 本月收入
        Column({ space: 4 }) {
          Text($r('app.string.monthly_income'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          
          Text(`¥${BillService.formatAmount(this.statistics.monthlyIncome)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.income_color'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        // 分割线
        Divider()
          .vertical(true)
          .height(40)
          .color($r('app.color.divider_color'))
        
        // 本月支出
        Column({ space: 4 }) {
          Text($r('app.string.monthly_expense'))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          
          Text(`¥${BillService.formatAmount(this.statistics.monthlyExpense)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.expense_color'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  // 构建快速记账按钮
  @Builder
  buildQuickActionButton() {
    Button($r('app.string.add_record'))
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor($r('app.color.primary_color'))
      .borderRadius(24)
      .onClick(() => {
        this.navigateToAddRecord()
      })
  }

  // 构建最近记录列表
  @Builder
  buildRecentRecords() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text($r('app.string.recent_records'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Blank()
        
        Text($r('app.string.view_all'))
          .fontSize(14)
          .fontColor($r('app.color.primary_color'))
          .onClick(() => {
            this.navigateToRecordList()
          })
      }
      .width('100%')
      
      // 记录列表
      if (this.recentRecords.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.recentRecords, (record: BillRecord) => {
            this.buildRecordItem(record)
          })
        }
        .width('100%')
      } else {
        // 空状态
        Column({ space: 8 }) {
          Text('🐻')
            .fontSize(32)
          
          Text($r('app.string.no_records'))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(40)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  // 构建单个记录项
  @Builder
  buildRecordItem(record: BillRecord) {
    Row({ space: 12 }) {
      // 分类图标
      Stack() {
        Text(this.getCategoryIcon(record.category))
          .fontSize(20)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.background_color'))
          .borderRadius(20)
        
        // 颜色指示器
        Circle({ width: 10, height: 10 })
          .fill(this.getCategoryColor(record.category))
          .stroke(Color.White)
          .strokeWidth(1)
          .position({ x: 30, y: 30 })
      }
      .width(40)
      .height(40)
      
      // 记录信息
      Column({ space: 2 }) {
        Row() {
          Text(record.category)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          
          if (record.note) {
            Text(`·${record.note}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        
        Text(record.date)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 金额
      Text(`${record.type === BillType.INCOME ? '+' : '-'}¥${BillService.formatAmount(record.amount)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(record.type === BillType.INCOME ? $r('app.color.income_color') : $r('app.color.expense_color'))
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  // 跳转到记账页面
  private navigateToAddRecord(): void {
    router.pushUrl({
      url: PagePath.ADD_RECORD
    })
  }

  // 跳转到账单列表页面
  private navigateToRecordList(): void {
    router.pushUrl({
      url: PagePath.BILL_LIST
    })
  }

  // 跳转到账户管理页面
  private navigateToAccountManage(): void {
    router.pushUrl({
      url: PagePath.ACCOUNT_MANAGE
    })
  }

  // 跳转到预算设置页面
  private navigateToBudgetSetting(): void {
    router.pushUrl({
      url: PagePath.BUDGET_SETTING
    })
  }

  // 跳转到统计页面
   navigateToStatistics() {
     router.pushUrl({
       url: PagePath.STATISTICS
     })
   }

  // 跳转到分类管理页面
  private navigateToCategoryManage(): void {
    router.pushUrl({
      url: PagePath.CATEGORY_MANAGE
    })
  }

  // 跳转到备份页面
  private navigateToBackup(): void {
    router.pushUrl({
      url: PagePath.BACKUP
    })
  }

  // 添加桌面卡片
  private addWidgetToDesktop(): void {
    try {
      // 这里可以调用系统API来添加桌面卡片
      // 或者显示添加卡片的引导信息
      AlertDialog.show({
        title: '添加桌面卡片',
        message: '长按桌面空白处，选择"服务卡片"，然后选择"熊宝记账"即可添加桌面卡片。',
        confirm: {
          value: '知道了',
          action: () => {}
        }
      })
    } catch (error) {
      console.error('Failed to show widget guide:', error)
    }
  }

  // 跳转到提醒设置页面
  private navigateToReminder(): void {
    router.pushUrl({
      url: 'pages/ReminderPage'
    })
  }

  // 构建账户概览
  @Builder
  buildAccountSection() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('我的账户')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Blank()
        
        Text('管理')
          .fontSize(14)
          .fontColor($r('app.color.primary_color'))
          .onClick(() => {
            this.navigateToAccountManage()
          })
      }
      .width('100%')
      
      // 账户列表
      if (this.accounts.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.accounts.slice(0, 3), (account: Account) => {
            Row() {
              Text(account.name)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              
              Text(`¥${BillService.formatAmount(account.balance)}`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          })
        }
        .width('100%')
      } else {
        Text('暂无账户')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .padding(20)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  // 获取分类图标
  private getCategoryIcon(category: string): string {
    const iconMap: Record<string, string> = {
      '餐饮': '🍽️',
      '交通': '🚗',
      '购物': '🛒',
      '娱乐': '🎮',
      '医疗': '🏥',
      '教育': '📚',
      '住房': '🏠',
      '工资': '💰',
      '奖金': '🎁',
      '投资': '📈',
      '兼职': '💼',
      '其他': '📝'
    }
    return iconMap[category] || '📝'
  }

  // 获取分类颜色
  private getCategoryColor(category: string): string {
    const categories = this.billService.getCategories(BillType.EXPENSE).concat(this.billService.getCategories(BillType.INCOME))
    const categoryObj = categories.find(cat => cat.name === category)
    return categoryObj?.color || '#FF6B6B'
  }

  // 构建统计入口
  @Builder
  buildStatisticsEntry() {
    Row() {
      Text('📊')
        .fontSize(20)
        .margin({ right: 12 })
      
      Text('数据统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      
      Text('查看详情')
        .fontSize(14)
        .fontColor($r('app.color.primary_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navigateToStatistics()
    })
  }

  // 构建分类管理入口
  @Builder
  buildCategoryManageEntry() {
    Row() {
      Text('🏷️')
        .fontSize(20)
        .margin({ right: 12 })
      
      Text('分类管理')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      
      Text('管理分类')
        .fontSize(14)
        .fontColor($r('app.color.primary_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navigateToCategoryManage()
    })
  }

  // 构建备份入口
  @Builder
  buildBackupEntry() {
    Row() {
      Text('💾')
        .fontSize(20)
        .margin({ right: 12 })
      
      Text('数据备份')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      
      Text('备份恢复')
        .fontSize(14)
        .fontColor($r('app.color.primary_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navigateToBackup()
    })
  }

  // 构建桌面卡片入口
  @Builder
  buildWidgetEntry() {
    Row() {
      Text('📱')
        .fontSize(20)
        .margin({ right: 12 })
      
      Text('桌面卡片')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      
      Text('添加卡片')
        .fontSize(14)
        .fontColor($r('app.color.primary_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.addWidgetToDesktop()
    })
  }

  // 构建提醒设置入口
  @Builder
  buildReminderEntry() {
    Row() {
      Text('🔔')
        .fontSize(20)
        .margin({ right: 12 })
      
      Text('提醒设置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      
      Text('设置提醒')
        .fontSize(14)
        .fontColor($r('app.color.primary_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navigateToReminder()
    })
  }

  // 构建预算概览
  @Builder
  buildBudgetSection() {
    Column({ space: 12 }) {
      // 标题行
      Row() {
        Text('本月预算')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Blank()
        
        Text('设置')
          .fontSize(14)
          .fontColor($r('app.color.primary_color'))
          .onClick(() => {
            this.navigateToBudgetSetting()
          })
      }
      .width('100%')
      
      // 预算信息
      if (this.currentBudgets.length > 0) {
        Column({ space: 8 }) {
          ForEach(this.currentBudgets.slice(0, 3), (budget: Budget) => {
            Row() {
              Column({ space: 4 }) {
                Text(budget.category)
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                
                Text(`已用 ¥${BillService.formatAmount(budget.spent)} / ¥${BillService.formatAmount(budget.amount)}`)
                   .fontSize(12)
                   .fontColor($r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              // 进度条
               Progress({
                 value: budget.spent,
                 total: budget.amount,
                 type: ProgressType.Linear
               })
                 .width(80)
                 .height(6)
                 .color(budget.spent > budget.amount ? $r('app.color.expense_color') : $r('app.color.primary_color'))
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
          })
        }
        .width('100%')
      } else {
        Text('暂无预算设置')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .padding(20)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  // 构建反馈中心入口
  @Builder
  buildFeedbackEntry() {
    Row() {
      Text('💬')
        .fontSize(20)
        .margin({ right: 12 })
      
      Text('反馈中心')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      
      Text('意见建议')
        .fontSize(14)
        .fontColor($r('app.color.primary_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navigateToFeedback()
    })
  }

  // 导航到反馈页面
  private navigateToFeedback() {
    // 跳转到企业微信二维码页面
    // HMRouterMgr.push({
    //   pageUrl: PagePath.QRCODE
    // })
    router.push({url:"pages/QRCodePage"})
  }
}