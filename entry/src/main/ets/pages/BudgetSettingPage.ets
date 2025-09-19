/**
 * 预算设置页面
 */

import { router } from '@kit.ArkUI'
import { BudgetService } from '../service/BudgetService'
import { Budget, BudgetType, BudgetStatistics } from '../model/Budget'
import { BillService } from '../service/BillService'
@Entry
@ComponentV2
export struct BudgetSettingPage {
  @Local budgets: Budget[] = []
  @Local statistics: BudgetStatistics = new BudgetStatistics()
  @Local showAddBudgetSheet: boolean = false
  @Local showEditBudgetSheet: boolean = false
  @Local editingBudget: Budget | null = null
  @Local selectedYear: number = new Date().getFullYear()
  @Local selectedMonth: number = new Date().getMonth() + 1
  
  // 新增预算表单数据
  @Local newBudgetType: BudgetType = BudgetType.MONTHLY
  @Local newBudgetName: string = ''
  @Local newBudgetAmount: string = ''
  @Local newBudgetCategory: string = ''
  @Local availableCategories: string[] = []
  
  private budgetService = BudgetService.getInstance()
  private billService = BillService.getInstance()

  aboutToAppear(): void {
    this.loadData()
  }

  // 加载数据
  private async loadData(): Promise<void> {
    this.budgets = await this.budgetService.getAllBudgets()
    this.statistics = await this.budgetService.getBudgetStatistics(this.selectedYear, this.selectedMonth)
    this.availableCategories = await this.billService.getAllCategories()
    
    // 更新所有预算的支出金额
    await this.budgetService.updateAllBudgetsSpent()
    this.budgets = await this.budgetService.getAllBudgets()
  }

  // 返回上一页
  private goBack(): void {
    router.back()
  }

  // 添加预算
  private async addBudget(): Promise<void> {
    if (!this.newBudgetName || !this.newBudgetAmount) {
      return
    }
    
    const budget = new Budget(
      0,
      this.newBudgetType,
      this.newBudgetName,
      parseFloat(this.newBudgetAmount),
      0,
      this.newBudgetType === BudgetType.CATEGORY ? this.newBudgetCategory : undefined,
      this.selectedYear,
      this.selectedMonth
    )
    
    const success = await this.budgetService.addBudget(budget)
    if (success) {
      this.showAddBudgetSheet = false
      this.resetForm()
      await this.loadData()
    }
  }

  // 编辑预算
  private async updateBudget(): Promise<void> {
    if (!this.editingBudget) return
    
    const success = await this.budgetService.updateBudget(this.editingBudget)
    if (success) {
      this.showEditBudgetSheet = false
      this.editingBudget = null
      await this.loadData()
    }
  }

  // 删除预算
  private async deleteBudget(budget: Budget): Promise<void> {
    const success = await this.budgetService.deleteBudget(budget.id)
    if (success) {
      await this.loadData()
    }
  }

  // 重置表单
  private resetForm(): void {
    this.newBudgetType = BudgetType.MONTHLY
    this.newBudgetName = ''
    this.newBudgetAmount = ''
    this.newBudgetCategory = ''
  }

  // 开始编辑预算
  private startEditBudget(budget: Budget): void {
    this.editingBudget = new Budget(
      budget.id,
      budget.type,
      budget.name,
      budget.amount,
      budget.spent,
      budget.category,
      budget.year,
      budget.month,
      budget.isActive,
      budget.createdAt,
      budget.updatedAt
    )
    this.showEditBudgetSheet = true
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildNavigationBar()
      
      Scroll() {
        Column({ space: 16 }) {
          // 预算统计概览
          this.buildStatisticsSection()
          
          // 月份选择
          this.buildMonthSelector()
          
          // 预算列表
          this.buildBudgetList()
        }
        .padding(16)
      }
      .layoutWeight(1)
      
      // 添加预算按钮
      this.buildAddButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
  }

  // 构建导航栏
  @Builder
  buildNavigationBar() {
    Row() {
      // Image($r('sys.symbol.chevron_left'))
      //   .width(24)
      //   .height(24)
      //   .fillColor($r('app.color.text_primary'))
      //   .onClick(() => {
      //     this.goBack()
      //   })
      Text('<  ')
        .width(24)
        .height(24)
        .fontColor('#333333')
        .onClick(() => {
          this.goBack()
        })
      
      Text('预算设置')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      
      // 占位
      Blank()
        .width(24)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_background'))
  }

  // 构建统计概览
  @Builder
  buildStatisticsSection() {
    Column({ space: 16 }) {
      Text('预算概览')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
      
      Row() {
        Column() {
          Text('总预算')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 4 })
          
          Text(`¥${this.statistics.totalBudget.toFixed(2)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary_color'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Divider()
          .vertical(true)
          .height(40)
          .color($r('app.color.divider_color'))
        
        Column() {
          Text('已支出')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 4 })
          
          Text(`¥${this.statistics.totalSpent.toFixed(2)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.expense_color'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        
        Divider()
          .vertical(true)
          .height(40)
          .color($r('app.color.divider_color'))
        
        Column() {
          Text('剩余')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 4 })
          
          Text(`¥${this.statistics.getTotalRemaining().toFixed(2)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.income_color'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(12)
    }
  }

  // 构建月份选择器
  @Builder
  buildMonthSelector() {
    Row() {
      Text('查看月份')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
      
      Blank()
      
      Text(`${this.selectedYear}年${this.selectedMonth}月`)
        .fontSize(16)
        .fontColor($r('app.color.primary_color'))
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(8)
  }

  // 构建预算列表
  @Builder
  buildBudgetList() {
    Column({ space: 12 }) {
      Text('预算列表')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
      
      if (this.budgets.length > 0) {
        ForEach(this.budgets.filter(budget => 
          budget.year === this.selectedYear && 
          budget.month === this.selectedMonth
        ), (budget: Budget) => {
          this.buildBudgetItem(budget)
        })
      } else {
        Column() {
          Text('暂无预算设置')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 8 })
          
          Text('点击下方按钮添加预算')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
        .padding(40)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(8)
        .width('100%')
      }
    }
  }

  // 构建预算项
  @Builder
  buildBudgetItem(budget: Budget) {
    Column({ space: 12 }) {
      Row() {
        Column() {
          Text(budget.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .alignSelf(ItemAlign.Start)
          
          if (budget.category) {
            Text(`分类：${budget.category}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .alignSelf(ItemAlign.Start)
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        
        Column() {
          Text(budget.getStatusText())
            .fontSize(12)
            .fontColor(budget.getStatusColor())
            .alignSelf(ItemAlign.End)
          
          Text(`¥${budget.spent.toFixed(2)} / ¥${budget.amount.toFixed(2)}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .alignSelf(ItemAlign.End)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      
      // 进度条
      Progress({
        value: budget.spent,
        total: budget.amount,
        type: ProgressType.Linear
      })
        .width('100%')
        .height(6)
        .color(budget.getStatusColor())
        .backgroundColor($r('app.color.divider_color'))
      
      // 操作按钮
      Row() {
        Button('编辑')
          .fontSize(12)
          .backgroundColor($r('app.color.primary_color'))
          .fontColor($r('app.color.white'))
          .borderRadius(4)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick(() => {
            this.startEditBudget(budget)
          })
          .bindSheet($$this.showEditBudgetSheet, this.buildEditBudgetSheet(), {
            height: 400
          })
        
        Button('删除')
          .fontSize(12)
          .backgroundColor($r('app.color.expense_color'))
          .fontColor($r('app.color.white'))
          .borderRadius(4)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .onClick(() => {
            this.deleteBudget(budget)
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(8)
    .onClick(() => {
      this.startEditBudget(budget)
    })
  }

  // 构建添加按钮
  @Builder
  buildAddButton() {
    Button('添加预算')
      .width('90%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor($r('app.color.primary_color'))
      .fontColor($r('app.color.white'))
      .borderRadius(24)
      .margin({ bottom: 20 })
      .onClick(() => {
        this.showAddBudgetSheet = true
      })
      .bindSheet($$this.showAddBudgetSheet, this.buildAddBudgetSheet(), {
        height: 500
      })
  }

  // 构建添加预算弹窗
  @Builder
  buildAddBudgetSheet() {
    Column({ space: 20 }) {
      Text('添加预算')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      // 预算类型选择
      Column({ space: 8 }) {
        Text('预算类型')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        Row() {
          Button('月度预算')
            .fontSize(14)
            .backgroundColor(this.newBudgetType === BudgetType.MONTHLY ? 
              $r('app.color.primary_color') : $r('app.color.background_color'))
            .fontColor(this.newBudgetType === BudgetType.MONTHLY ? 
              $r('app.color.white') : $r('app.color.text_primary'))
            .borderRadius(6)
            .layoutWeight(1)
            .onClick(() => {
              this.newBudgetType = BudgetType.MONTHLY
              this.newBudgetName = '月度预算'
            })
          
          Button('分类预算')
            .fontSize(14)
            .backgroundColor(this.newBudgetType === BudgetType.CATEGORY ? 
              $r('app.color.primary_color') : $r('app.color.background_color'))
            .fontColor(this.newBudgetType === BudgetType.CATEGORY ? 
              $r('app.color.white') : $r('app.color.text_primary'))
            .borderRadius(6)
            .layoutWeight(1)
            .onClick(() => {
              this.newBudgetType = BudgetType.CATEGORY
              this.newBudgetName = ''
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      
      // 预算名称
      Column({ space: 8 }) {
        Text('预算名称')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        TextInput({ placeholder: '请输入预算名称', text: this.newBudgetName })
          .fontSize(16)
          .backgroundColor($r('app.color.background_color'))
          .borderRadius(8)
          .onChange((value: string) => {
            this.newBudgetName = value
          })
      }
      
      // 分类选择（仅分类预算显示）
      if (this.newBudgetType === BudgetType.CATEGORY) {
        Column({ space: 8 }) {
          Text('选择分类')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .alignSelf(ItemAlign.Start)
          
          // 简化的分类选择
          TextInput({ placeholder: '请输入分类名称', text: this.newBudgetCategory })
            .fontSize(16)
            .backgroundColor($r('app.color.background_color'))
            .borderRadius(8)
            .onChange((value: string) => {
              this.newBudgetCategory = value
            })
        }
      }
      
      // 预算金额
      Column({ space: 8 }) {
        Text('预算金额')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        TextInput({ placeholder: '请输入预算金额', text: this.newBudgetAmount })
          .fontSize(16)
          .type(InputType.Number)
          .backgroundColor($r('app.color.background_color'))
          .borderRadius(8)
          .onChange((value: string) => {
            this.newBudgetAmount = value
          })
      }
      
      // 操作按钮
      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor($r('app.color.background_color'))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.showAddBudgetSheet = false
            this.resetForm()
          })
        
        Button('确定')
          .fontSize(16)
          .backgroundColor($r('app.color.primary_color'))
          .fontColor($r('app.color.white'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.addBudget()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
  }

  // 构建编辑预算弹窗
  @Builder
  buildEditBudgetSheet() {
    Column({ space: 20 }) {
      Text('编辑预算')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      // 预算名称
      Column({ space: 8 }) {
        Text('预算名称')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        TextInput({ placeholder: '请输入预算名称', text: this.editingBudget?.name || '' })
          .fontSize(16)
          .backgroundColor($r('app.color.background_color'))
          .borderRadius(8)
          .onChange((value: string) => {
            if (this.editingBudget) {
              this.editingBudget.name = value
            }
          })
      }
      
      // 预算金额
      Column({ space: 8 }) {
        Text('预算金额')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        TextInput({ placeholder: '请输入预算金额', text: this.editingBudget?.amount.toString() || '' })
          .fontSize(16)
          .type(InputType.Number)
          .backgroundColor($r('app.color.background_color'))
          .borderRadius(8)
          .onChange((value: string) => {
            if (this.editingBudget) {
              this.editingBudget.amount = parseFloat(value) || 0
            }
          })
      }
      
      // 操作按钮
      Row() {
        Button('取消')
          .fontSize(16)
          .backgroundColor($r('app.color.background_color'))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.showEditBudgetSheet = false
            this.editingBudget = null
          })
        
        Button('保存')
          .fontSize(16)
          .backgroundColor($r('app.color.primary_color'))
          .fontColor($r('app.color.white'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.updateBudget()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
  }
}