import { ExportService } from '../service/ExportService'
import { BillService } from '../service/BillService'
import { BillRecord, BillType } from '../model/BillRecord'
import { router } from '@kit.ArkUI'

@Entry
@ComponentV2
export struct ExportPage {
  @Local exportService: ExportService = ExportService.getInstance()
  @Local billService: BillService = BillService.getInstance()
  @Local selectedFormat: string = 'CSV'
  @Local selectedType: string = '全部'
  @Local selectedCategory: string = '全部'
  @Local startDate: string = ''
  @Local endDate: string = ''
  @Local isExporting: boolean = false
  @Local exportResult: string = ''
  @Local showDatePicker: boolean = false
  @Local datePickerType: string = 'start' // 'start' or 'end'
  @Local selectedDate: Date = new Date()
  @Local categories: string[] = []
  
  private formatOptions = ['CSV', 'Excel']
  private typeOptions = ['全部', '收入', '支出']

  aboutToAppear() {
    this.initializeDates()
    this.loadCategories()
  }

  private initializeDates() {
    const today = new Date()
    const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)
    
    this.endDate = today.toISOString().split('T')[0]
    this.startDate = firstDayOfMonth.toISOString().split('T')[0]
  }

  private loadCategories() {
    const expenseCategories = this.billService.getCategories(BillType.EXPENSE)
    const incomeCategories = this.billService.getCategories(BillType.INCOME)
    
    this.categories = ['全部']
    expenseCategories.forEach(cat => this.categories.push(cat.name))
    incomeCategories.forEach(cat => this.categories.push(cat.name))
  }

  build() {
    Column() {
      // 标题栏
      this.buildHeader()
      
      // 导出配置
      this.buildExportConfig()
      
      // 预览信息
      this.buildPreviewInfo()
      
      // 导出按钮
      this.buildExportButton()
      
      // 导出结果
      if (this.exportResult) {
        this.buildExportResult()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
    .bindSheet($$this.showDatePicker, this.buildDatePicker, {
      height: 400
    })
  }

  // 构建标题栏
  @Builder
  buildHeader() {
    Row() {
      Button('返回')
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .fontColor($r('app.color.primary_color'))
        .onClick(() => {
          router.back()
        })
      
      Text('数据导出')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 占位
      Button()
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .width(60)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_background'))
  }

  // 构建导出配置
  @Builder
  buildExportConfig() {
    Column({ space: 16 }) {
      Text('导出配置')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
      
      // 导出格式
      this.buildFormatSelector()
      
      // 数据类型
      this.buildTypeSelector()
      
      // 分类筛选
      this.buildCategorySelector()
      
      // 日期范围
      this.buildDateRangeSelector()
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 8, left: 16, right: 16 })
  }

  // 构建格式选择器
  @Builder
  buildFormatSelector() {
    Column({ space: 8 }) {
      Text('导出格式')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 12 }) {
        ForEach(this.formatOptions, (format: string) => {
          Button(format)
            .type(ButtonType.Normal)
            .backgroundColor(this.selectedFormat === format ? $r('app.color.primary_color') : $r('app.color.background_color'))
            .fontColor(this.selectedFormat === format ? Color.White : $r('app.color.text_primary'))
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => {
              this.selectedFormat = format
            })
        })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 构建类型选择器
  @Builder
  buildTypeSelector() {
    Column({ space: 8 }) {
      Text('数据类型')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 12 }) {
        ForEach(this.typeOptions, (type: string) => {
          Button(type)
            .type(ButtonType.Normal)
            .backgroundColor(this.selectedType === type ? $r('app.color.primary_color') : $r('app.color.background_color'))
            .fontColor(this.selectedType === type ? Color.White : $r('app.color.text_primary'))
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => {
              this.selectedType = type
            })
        })
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 构建分类选择器
  @Builder
  buildCategorySelector() {
    Column({ space: 8 }) {
      Text('分类筛选')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      Button(this.selectedCategory)
        .type(ButtonType.Normal)
        .backgroundColor($r('app.color.background_color'))
        .fontColor($r('app.color.text_primary'))
        .borderRadius(8)
        .width('100%')
        .onClick(() => {
          // 这里可以实现分类选择弹窗
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 构建日期范围选择器
  @Builder
  buildDateRangeSelector() {
    Column({ space: 8 }) {
      Text('日期范围')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('开始日期')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          
          Button(this.startDate)
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.background_color'))
            .fontColor($r('app.color.text_primary'))
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => {
              this.datePickerType = 'start'
              this.selectedDate = new Date(this.startDate)
              this.showDatePicker = true
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        
        Column({ space: 4 }) {
          Text('结束日期')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          
          Button(this.endDate)
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.background_color'))
            .fontColor($r('app.color.text_primary'))
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => {
              this.datePickerType = 'end'
              this.selectedDate = new Date(this.endDate)
              this.showDatePicker = true
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 构建预览信息
  @Builder
  buildPreviewInfo() {
    Column({ space: 12 }) {
      Text('数据预览')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
      
      Text(this.exportService.generateExportSummary(this.getFilteredRecords()))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 8, left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  // 构建导出按钮
  @Builder
  buildExportButton() {
    Button(this.isExporting ? '导出中...' : '开始导出')
      .type(ButtonType.Normal)
      .backgroundColor($r('app.color.primary_color'))
      .fontColor(Color.White)
      .borderRadius(12)
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .margin({ top: 16, left: 16, right: 16 })
      .enabled(!this.isExporting)
      .onClick(() => {
        this.performExport()
      })
  }

  // 构建导出结果
  @Builder
  buildExportResult() {
    Column({ space: 8 }) {
      Text('导出结果')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
      
      Text(this.exportResult)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .lineHeight(20)
        .alignSelf(ItemAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 8, left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
  }

  // 构建日期选择器
  @Builder
  buildDatePicker() {
    Column({ space: 20 }) {
      Text(`选择${this.datePickerType === 'start' ? '开始' : '结束'}日期`)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      DatePicker({
        start: new Date('2020-1-1'),
        end: new Date(),
        selected: this.selectedDate
      })
        .onChange((value: DatePickerResult) => {
          this.selectedDate = new Date(value.year!, value.month!, value.day!)
        })
      
      Row({ space: 12 }) {
        Button('取消')
          .type(ButtonType.Normal)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .onClick(() => {
            this.showDatePicker = false
          })
        
        Button('确定')
          .type(ButtonType.Normal)
          .backgroundColor($r('app.color.primary_color'))
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            const dateStr = this.selectedDate.toISOString().split('T')[0]
            if (this.datePickerType === 'start') {
              this.startDate = dateStr
            } else {
              this.endDate = dateStr
            }
            this.showDatePicker = false
          })
      }
      .width('100%')
    }
    .padding(20)
  }

  // 获取筛选后的记录
  private getFilteredRecords(): BillRecord[] {
    let records = this.exportService.getRecordsByDateRange(this.startDate, this.endDate)
    
    // 按类型筛选
    if (this.selectedType !== '全部') {
      const type = this.selectedType === '收入' ? BillType.INCOME : BillType.EXPENSE
      records = records.filter(r => r.type === type)
    }
    
    // 按分类筛选
    if (this.selectedCategory !== '全部') {
      records = records.filter(r => r.category === this.selectedCategory)
    }
    
    return records
  }

  // 执行导出
  private async performExport() {
    this.isExporting = true
    this.exportResult = ''
    
    try {
      const records = this.getFilteredRecords()
      
      if (records.length === 0) {
        this.exportResult = '没有符合条件的数据可导出'
        return
      }
      
      const fileName = `账单数据_${this.startDate}_${this.endDate}`
      let success = false
      
      if (this.selectedFormat === 'CSV') {
        success = await this.exportService.exportToCSV(records, `${fileName}.csv`)
      } else {
        success = await this.exportService.exportToExcel(records, `${fileName}.xlsx`)
      }
      
      if (success) {
        this.exportResult = `导出成功！\n共导出 ${records.length} 条记录\n格式：${this.selectedFormat}\n文件名：${fileName}`
      } else {
        this.exportResult = '导出失败，请重试'
      }
    } catch (error) {
      this.exportResult = `导出出错：${error}`
    } finally {
      this.isExporting = false
    }
  }
}