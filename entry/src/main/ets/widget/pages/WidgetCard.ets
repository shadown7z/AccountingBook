import { WidgetService, WidgetData } from '../../service/WidgetService'

/**
 * 桌面卡片UI组件
 * 提供快速记账和数据展示功能
 */
@Entry
@Component
struct WidgetCard {
  @State widgetData: WidgetData = this.getDefaultWidgetData()
  
  @State showQuickActions: boolean = false
  @State quickAmount: string = ''
  
  private widgetService = WidgetService.getInstance()
  
  aboutToAppear(): void {
    this.loadWidgetData()
  }
  
  // 加载卡片数据
  async loadWidgetData() {
    try {
      this.widgetData = await this.widgetService.getWidgetData()
    } catch (error) {
      console.error('Failed to load widget data:', error)
    }
  }
  
  // 获取默认卡片数据
  private getDefaultWidgetData(): WidgetData {
    const defaultData: WidgetData = {
      todayIncome: 0,
      todayExpense: 0,
      monthIncome: 0,
      monthExpense: 0,
      totalBalance: 0,
      recentBills: [],
      lastUpdateTime: ''
    }
    return defaultData
  }
  
  // 快速添加收入
  async quickAddIncome(amount: number) {
    try {
      const success = await this.widgetService.quickAddIncome(amount)
      if (success) {
        await this.loadWidgetData()
        const actionData: Record<string, Object> = {}
        actionData['amount'] = amount
        actionData['success'] = true
        this.postAction('quickIncome', actionData)
      }
    } catch (error) {
      console.error('Failed to quick add income:', error)
    }
  }
  
  // 快速添加支出
  async quickAddExpense(amount: number) {
    try {
      const success = await this.widgetService.quickAddExpense(amount)
      if (success) {
        await this.loadWidgetData()
        const actionData: Record<string, Object> = {}
        actionData['amount'] = amount
        actionData['success'] = true
        this.postAction('quickExpense', actionData)
      }
    } catch (error) {
      console.error('Failed to quick add expense:', error)
    }
  }
  
  // 发送卡片事件
  private postAction(action: string, data: Record<string, Object>) {
    try {
      // 卡片事件处理，这里可以通过其他方式与主应用通信
      console.info(`Widget action: ${action}`, data)
    } catch (error) {
      console.error('Failed to post card action:', error)
    }
  }
  
  // 格式化金额
  private formatAmount(amount: number): string {
    return amount.toFixed(2)
  }
  
  // 格式化时间
  private formatTime(): string {
    const now = new Date()
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
  }
  
  // 获取本月结余
  private getMonthBalance(): number {
    return this.widgetData.monthIncome - this.widgetData.monthExpense
  }
  
  build() {
    Column() {
      // 头部信息
      this.buildHeader()
      
      // 今日数据
      this.buildTodayData()
      
      // 快速操作
      this.buildQuickActions()
      
      // 余额信息
      this.buildBalanceInfo()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding(16)
  }
  
  // 卡片头部
  @Builder
  buildHeader() {
    Row() {
      Text('🐻 熊宝记账')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .layoutWeight(1)
      
      Text(this.formatTime())
        .fontSize(12)
        .fontColor('#999999')
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
  
  // 今日数据
  @Builder
  buildTodayData() {
    Row() {
      // 今日收入
      Column() {
        Text('今日收入')
          .fontSize(10)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        
        Text(`+${this.formatAmount(this.widgetData.todayIncome)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#4CAF50')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 今日支出
      Column() {
        Text('今日支出')
          .fontSize(10)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        
        Text(`-${this.formatAmount(this.widgetData.todayExpense)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FF5722')
      }
      .alignItems(HorizontalAlign.End)
      .layoutWeight(1)
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
  
  // 快速操作
  @Builder
  buildQuickActions() {
    Row({ space: 8 }) {
      // 快速收入按钮
      Button() {
        Row() {
          Text('💰')
            .fontSize(12)
            .margin({ right: 4 })
          Text('收入')
            .fontSize(10)
            .fontColor('#FFFFFF')
        }
      }
      .backgroundColor('#4CAF50')
      .borderRadius(8)
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .layoutWeight(1)
      .onClick(() => {
        this.quickAddIncome(100) // 默认100元
      })
      
      // 快速支出按钮
      Button() {
        Row() {
          Text('💸')
            .fontSize(12)
            .margin({ right: 4 })
          Text('支出')
            .fontSize(10)
            .fontColor('#FFFFFF')
        }
      }
      .backgroundColor('#FF5722')
      .borderRadius(8)
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .layoutWeight(1)
      .onClick(() => {
        this.quickAddExpense(50) // 默认50元
      })
      
      // 打开应用按钮
      Button() {
        Row() {
          Text('📱')
            .fontSize(12)
            .margin({ right: 4 })
          Text('打开')
            .fontSize(10)
            .fontColor('#FFFFFF')
        }
      }
      .backgroundColor('#2196F3')
      .borderRadius(8)
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .layoutWeight(1)
      .onClick(() => {
        // 打开主应用
        this.postAction('openApp', {})
      })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
  
  // 余额信息
  @Builder
  buildBalanceInfo() {
    Row() {
      Column() {
        Text('账户余额')
          .fontSize(10)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        
        Text(`¥${this.formatAmount(this.widgetData.totalBalance)}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 本月统计
      Column() {
        Text('本月结余')
          .fontSize(10)
          .fontColor('#666666')
          .margin({ bottom: 4 })
        
        Text(`${this.getMonthBalance() >= 0 ? '+' : ''}${this.formatAmount(this.getMonthBalance())}`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getMonthBalance() >= 0 ? '#4CAF50' : '#FF5722')
      }
      .alignItems(HorizontalAlign.End)
      .layoutWeight(1)
    }
    .width('100%')
  }
}