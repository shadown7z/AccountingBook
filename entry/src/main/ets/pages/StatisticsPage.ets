import { HMRouter } from '@hadss/hmrouter'
import { BillService } from '../service/BillService'
import { BillRecord, BillType } from '../model/BillRecord'
import { PAGE_PATH } from '../constants/PagePath'

// 趋势数据映射值接口
interface TrendMapValue {
  income: number
  expense: number
}

@Entry
@HMRouter({ pageUrl: PAGE_PATH.STATISTICS })
@ComponentV2
export struct StatisticsPage {
  @Local selectedYear: number = new Date().getFullYear()
  @Local selectedMonth: number = new Date().getMonth() + 1
  @Local monthlyData: MonthlyStatistics = {
    totalIncome: 0,
    totalExpense: 0,
    balance: 0,
    recordCount: 0,
    avgDaily: 0
  }
  @Local categoryData: CategoryStatistics[] = []
  @Local trendData: TrendData[] = []
  @Local showYearPicker: boolean = false
  @Local showMonthPicker: boolean = false
  
  private billService = BillService.getInstance()
  
  aboutToAppear(): void {
    this.loadStatisticsData()
  }
  
  // 加载统计数据
  async loadStatisticsData() {
    await this.loadMonthlyData()
    await this.loadCategoryData()
    await this.loadTrendData()
  }
  
  // 加载月度统计数据
  async loadMonthlyData() {
    const records = this.billService.getBillRecords()
    const monthRecords = records.filter(record => {
      const date = new Date(record.date)
      return date.getFullYear() === this.selectedYear && 
             date.getMonth() + 1 === this.selectedMonth
    })
    
    let totalIncome = 0
    let totalExpense = 0
    let recordCount = 0
    
    monthRecords.forEach(record => {
      if (record.type === BillType.INCOME) {
        totalIncome += record.amount
      } else {
        totalExpense += record.amount
      }
      recordCount++
    })
    
    this.monthlyData = {
      totalIncome,
      totalExpense,
      balance: totalIncome - totalExpense,
      recordCount,
      avgDaily: recordCount > 0 ? totalExpense / new Date(this.selectedYear, this.selectedMonth, 0).getDate() : 0
    }
  }
  
  // 加载分类统计数据
  async loadCategoryData() {
    const records = this.billService.getBillRecords()
    const monthRecords = records.filter(record => {
      const date = new Date(record.date)
      return record.type === BillType.EXPENSE &&
             date.getFullYear() === this.selectedYear && 
             date.getMonth() + 1 === this.selectedMonth
    })
    
    const categoryMap = new Map<string, number>()
    monthRecords.forEach(record => {
      const current = categoryMap.get(record.category) || 0
      categoryMap.set(record.category, current + record.amount)
    })
    
    const totalExpense = this.monthlyData.totalExpense
    this.categoryData = Array.from(categoryMap.entries())
      .map((entry) => {
        const category = entry[0]
        const amount = entry[1]
        const categoryItem: CategoryStatistics = {
          category,
          amount,
          percentage: totalExpense > 0 ? (amount / totalExpense) * 100 : 0
        }
        return categoryItem
      })
      .sort((a, b) => b.amount - a.amount)
  }
  
  // 加载趋势数据
  async loadTrendData() {
    const records = this.billService.getBillRecords()
    const trendMap = new Map<string, TrendMapValue>()
    
    // 获取最近6个月的数据
    for (let i = 5; i >= 0; i--) {
      const date = new Date(this.selectedYear, this.selectedMonth - 1 - i, 1)
      const year = date.getFullYear()
      const month = date.getMonth() + 1
      const key = `${year}-${month.toString().padStart(2, '0')}`
      
      const monthRecords = records.filter(record => {
        const recordDate = new Date(record.date)
        return recordDate.getFullYear() === year && 
               recordDate.getMonth() + 1 === month
      })
      
      let income = 0
      let expense = 0
      monthRecords.forEach(record => {
        if (record.type === BillType.INCOME) {
          income += record.amount
        } else {
          expense += record.amount
        }
      })
      
      const trendValue: TrendMapValue = { income, expense }
      trendMap.set(key, trendValue)
    }
    
    this.trendData = Array.from(trendMap.entries()).map((entry) => {
      const month = entry[0]
      const data = entry[1]
      const trendItem: TrendData = {
        month,
        income: data.income,
        expense: data.expense,
        balance: data.income - data.expense
      }
      return trendItem
    })
  }
  
  build() {
    Column() {
      // 顶部导航
      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .width(20)
            .height(20)
            .fontColor(['#333333'])
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          // 返回上一页
        })
        
        Text('数据统计')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.background_primary'))
      
      Scroll() {
        Column({ space: 16 }) {
          // 时间选择器
          this.buildTimeSelector()
          
          // 月度概览
          this.buildMonthlyOverview()
          
          // 分类统计
          this.buildCategoryStatistics()
          
          // 趋势分析
          this.buildTrendAnalysis()
        }
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_secondary'))
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showYearPicker, this.yearPickerBuilder, {
      height: 300
    })
    .bindSheet($$this.showMonthPicker, this.monthPickerBuilder, {
      height: 300
    })
  }
  
  // 时间选择器
  @Builder
  buildTimeSelector() {
    Row() {
      Button(`${this.selectedYear}年`)
        .backgroundColor($r('app.color.background_primary'))
        .fontColor($r('app.color.text_primary'))
        .borderRadius(8)
        .onClick(() => {
          this.showYearPicker = true
        })
      
      Button(`${this.selectedMonth}月`)
        .backgroundColor($r('app.color.background_primary'))
        .fontColor($r('app.color.text_primary'))
        .borderRadius(8)
        .margin({ left: 12 })
        .onClick(() => {
          this.showMonthPicker = true
        })
      
      Blank()
      
      Button('刷新')
        .backgroundColor($r('app.color.primary_color'))
        .fontColor(Color.White)
        .borderRadius(8)
        .onClick(() => {
          this.loadStatisticsData()
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 月度概览
  @Builder
  buildMonthlyOverview() {
    Column() {
      Text('月度概览')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })
      
      Row() {
        // 收入
        Column() {
          Text('总收入')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`¥${BillService.formatAmount(this.monthlyData.totalIncome)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.income_color'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        
        // 支出
        Column() {
          Text('总支出')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`¥${BillService.formatAmount(this.monthlyData.totalExpense)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.expense_color'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        
        // 结余
        Column() {
          Text('结余')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`¥${BillService.formatAmount(this.monthlyData.balance)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.monthlyData.balance >= 0 ? $r('app.color.income_color') : $r('app.color.expense_color'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
      
      Divider()
        .margin({ top: 16, bottom: 16 })
      
      Row() {
        Column() {
          Text('记录笔数')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.monthlyData.recordCount}笔`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        
        Column() {
          Text('日均支出')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`¥${BillService.formatAmount(this.monthlyData.avgDaily)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 分类统计
  @Builder
  buildCategoryStatistics() {
    Column() {
      Text('分类统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })
      
      if (this.categoryData.length > 0) {
        ForEach(this.categoryData, (item: CategoryStatistics) => {
          Row() {
            Column() {
              Text(item.category)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
              Text(`${item.percentage.toFixed(1)}%`)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            
            Text(`¥${BillService.formatAmount(item.amount)}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.expense_color'))
            
            // 进度条
            Progress({
              value: item.percentage,
              total: 100,
              type: ProgressType.Linear
            })
              .width(60)
              .height(6)
              .color($r('app.color.expense_color'))
              .margin({ left: 12 })
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        })
      } else {
        Text('暂无数据')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding(20)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 趋势分析
  @Builder
  buildTrendAnalysis() {
    Column() {
      Text('趋势分析')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })
      
      if (this.trendData.length > 0) {
        ForEach(this.trendData, (item: TrendData) => {
          Column() {
            Row() {
              Text(item.month)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
              
              Text(`结余: ¥${BillService.formatAmount(item.balance)}`)
                .fontSize(12)
                .fontColor(item.balance >= 0 ? $r('app.color.income_color') : $r('app.color.expense_color'))
            }
            .width('100%')
            .margin({ bottom: 8 })
            
            Row() {
              // 收入条
              Row()
                .width(`${item.income > 0 ? Math.max(item.income / Math.max(...this.trendData.map(d => Math.max(d.income, d.expense))) * 100, 5) : 0}%`)
                .height(8)
                .backgroundColor($r('app.color.income_color'))
                .borderRadius(4)
              
              Blank()
              
              Text(`¥${BillService.formatAmount(item.income)}`)
                .fontSize(12)
                .fontColor($r('app.color.income_color'))
            }
            .width('100%')
            .margin({ bottom: 4 })
            
            Row() {
              // 支出条
              Row()
                .width(`${item.expense > 0 ? Math.max(item.expense / Math.max(...this.trendData.map(d => Math.max(d.income, d.expense))) * 100, 5) : 0}%`)
                .height(8)
                .backgroundColor($r('app.color.expense_color'))
                .borderRadius(4)
              
              Blank()
              
              Text(`¥${BillService.formatAmount(item.expense)}`)
                .fontSize(12)
                .fontColor($r('app.color.expense_color'))
            }
            .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.background_secondary'))
          .borderRadius(8)
          .margin({ bottom: 8 })
        })
      } else {
        Text('暂无数据')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding(20)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 年份选择器
  @Builder
  yearPickerBuilder() {
    Column() {
      Text('选择年份')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      TextPicker({
        range: new Array(10).fill(0).map((_: number, i: number) => (new Date().getFullYear() - 5 + i).toString()),
        selected: 5
      })
        .onChange((value: string | string[], index: number | number[]) => {
          if (typeof value === 'string') {
            this.selectedYear = parseInt(value)
          }
        })
      
      Row() {
        Button('取消')
          .backgroundColor($r('app.color.background_secondary'))
          .fontColor($r('app.color.text_primary'))
          .onClick(() => {
            this.showYearPicker = false
          })
        
        Button('确定')
          .backgroundColor($r('app.color.primary_color'))
          .fontColor(Color.White)
          .margin({ left: 20 })
          .onClick(() => {
            this.showYearPicker = false
            this.loadStatisticsData()
          })
      }
      .margin({ top: 20 })
    }
    .padding(20)
  }
  
  // 月份选择器
  @Builder
  monthPickerBuilder() {
    Column() {
      Text('选择月份')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      TextPicker({
        range: new Array(12).fill(0).map((_: number, i: number) => `${i + 1}月`),
        selected: this.selectedMonth - 1
      })
        .onChange((value: string | string[], index: number | number[]) => {
          if (typeof value === 'string') {
            this.selectedMonth = parseInt(value.replace('月', ''))
          }
        })
      
      Row() {
        Button('取消')
          .backgroundColor($r('app.color.background_secondary'))
          .fontColor($r('app.color.text_primary'))
          .onClick(() => {
            this.showMonthPicker = false
          })
        
        Button('确定')
          .backgroundColor($r('app.color.primary_color'))
          .fontColor(Color.White)
          .margin({ left: 20 })
          .onClick(() => {
            this.showMonthPicker = false
            this.loadStatisticsData()
          })
      }
      .margin({ top: 20 })
    }
    .padding(20)
  }
}

// 月度统计数据接口
interface MonthlyStatistics {
  totalIncome: number
  totalExpense: number
  balance: number
  recordCount: number
  avgDaily: number
}

// 分类统计数据接口
interface CategoryStatistics {
  category: string
  amount: number
  percentage: number
}

// 趋势数据接口
interface TrendData {
  month: string
  income: number
  expense: number
  balance: number
}