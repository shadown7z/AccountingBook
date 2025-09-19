import { BillService } from '../service/BillService'
import { BillRecord, BillType } from '../model/BillRecord'
import { router } from '@kit.ArkUI'

@Entry
@ComponentV2
export struct BillListPage {
  @Local billService: BillService = BillService.getInstance()
  @Local billRecords: BillRecord[] = []
  @Local selectedMonth: string = ''
  @Local showMonthPicker: boolean = false
  @Local monthlyIncome: number = 0
  @Local monthlyExpense: number = 0

  aboutToAppear() {
    this.selectedMonth = new Date().toISOString().slice(0, 7) // YYYY-MM
    this.loadBillRecords()
  }

  private loadBillRecords() {
    const allRecords = this.billService.getBillRecords()
    this.billRecords = allRecords.filter(record => record.date.startsWith(this.selectedMonth))
    this.calculateMonthlyStats()
  }

  private calculateMonthlyStats() {
    this.monthlyIncome = this.billRecords
      .filter(record => record.type === BillType.INCOME)
      .reduce((sum, record) => sum + record.amount, 0)
    
    this.monthlyExpense = this.billRecords
      .filter(record => record.type === BillType.EXPENSE)
      .reduce((sum, record) => sum + record.amount, 0)
  }

  private formatMonth(month: string): string {
    const date = new Date(month + '-01')
    return `${date.getFullYear()}年${date.getMonth() + 1}月`
  }

  private generateMonthOptions(): string[] {
    const months: string[] = []
    const currentDate = new Date()
    
    // 生成过去12个月的选项
    for (let i = 0; i < 12; i++) {
      const date = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1)
      const monthStr = date.toISOString().slice(0, 7)
      months.push(monthStr)
    }
    
    return months
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()
      
      // 月度统计
      this.buildMonthlyStats()
      
      // 账单列表
      this.buildBillList()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
    .bindSheet($$this.showMonthPicker, this.buildMonthPicker(), {
      height: 300
    })
  }

  // 构建顶部导航栏
  @Builder
  buildHeader() {
    Row() {
      Text('返回')
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .onClick(() => {
          router.back()
        })
      
      Blank()
      
      Row({ space: 4 }) {
        Text(this.formatMonth(this.selectedMonth))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Text('▼')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .onClick(() => {
        this.showMonthPicker = true
      })
      
      Blank()
      
      Text('')
        .width(32)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_background'))
  }

  // 构建月度统计
  @Builder
  buildMonthlyStats() {
    Row() {
      // 收入
      Column({ space: 4 }) {
        Text($r('app.string.income'))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        
        Text(`¥${BillService.formatAmount(this.monthlyIncome)}`)
          .fontSize(18)
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
      
      // 支出
      Column({ space: 4 }) {
        Text($r('app.string.expense'))
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        
        Text(`¥${BillService.formatAmount(this.monthlyExpense)}`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.expense_color'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      
      // 分割线
      Divider()
        .vertical(true)
        .height(40)
        .color($r('app.color.divider_color'))
      
      // 结余
      Column({ space: 4 }) {
        Text('结余')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
        
        Text(`¥${BillService.formatAmount(this.monthlyIncome - this.monthlyExpense)}`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .margin({ left: 16, right: 16, top: 16 })
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  // 构建账单列表
  @Builder
  buildBillList() {
    if (this.billRecords.length > 0) {
      List({ space: 8 }) {
        ForEach(this.billRecords, (record: BillRecord) => {
          ListItem() {
            this.buildBillItem(record)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    } else {
      // 空状态
      Column({ space: 16 }) {
        Text('🐻')
          .fontSize(48)
        
        Text('本月暂无记录')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
        
        Text('快去记录第一笔账单吧~')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }

  // 构建单个账单项
  @Builder
  buildBillItem(record: BillRecord) {
    Row({ space: 12 }) {
      // 分类图标
      Stack() {
        Text(this.getCategoryIcon(record.category))
          .fontSize(24)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.background_color'))
          .borderRadius(24)
        
        // 颜色指示器
        Circle({ width: 12, height: 12 })
          .fill(this.getCategoryColor(record.category))
          .stroke(Color.White)
          .strokeWidth(1)
          .position({ x: 36, y: 36 })
      }
      .width(48)
      .height(48)
      
      // 记录信息
      Column({ space: 4 }) {
        Row() {
          Text(record.category)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          
          if (record.note) {
            Text(`·${record.note}`)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
        }
        .width('100%')
        
        Row({ space: 8 }) {
          Text(this.formatDate(record.date))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          
          Text(this.formatTime(record.createTime))
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 金额
      Text(`${record.type === BillType.INCOME ? '+' : '-'}¥${BillService.formatAmount(record.amount)}`)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(record.type === BillType.INCOME ? $r('app.color.income_color') : $r('app.color.expense_color'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  // 构建月份选择器
  @Builder
  buildMonthPicker() {
    Column({ space: 16 }) {
      Text('选择月份')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      List({ space: 8 }) {
        ForEach(this.generateMonthOptions(), (month: string) => {
          ListItem() {
            Row() {
              Text(this.formatMonth(month))
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              
              if (month === this.selectedMonth) {
                Text('✓')
                  .fontSize(16)
                  .fontColor($r('app.color.primary_color'))
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor(month === this.selectedMonth ? $r('app.color.background_color') : Color.Transparent)
            .borderRadius(8)
            .onClick(() => {
              this.selectedMonth = month
              this.loadBillRecords()
              this.showMonthPicker = false
            })
          }
        })
      }
      .width('100%')
      .height(200)
    }
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
  }

  // 格式化日期显示
  private formatDate(dateStr: string): string {
    const date = new Date(dateStr)
    const today = new Date()
    const yesterday = new Date(today.getTime() - 24 * 60 * 60 * 1000)
    
    if (dateStr === today.toISOString().split('T')[0]) {
      return '今天'
    } else if (dateStr === yesterday.toISOString().split('T')[0]) {
      return '昨天'
    } else {
      return `${date.getMonth() + 1}月${date.getDate()}日`
    }
  }

  // 格式化时间显示
  private formatTime(timeStr: string): string {
    const date = new Date(timeStr)
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
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
}