import { BillService } from '../service/BillService'
import { BillRecord, BillType, BillCategory } from '../model/BillRecord'
import { AccountService } from '../service/AccountService'
import { Account } from '../model/Account'
import { PagePath } from '../constants/PagePath'
import { router } from '@kit.ArkUI'

@Entry
@ComponentV2
export struct AddRecordPage {
  @Local billService: BillService = BillService.getInstance()
  @Local currentType: BillType = BillType.EXPENSE
  @Local amount: string = ''
  @Local selectedCategory: string = ''
  @Local note: string = ''
  @Local categories: BillCategory[] = []
  @Local showCategoryPicker: boolean = false
  @Local selectedAccount: Account | null = null
  @Local accounts: Account[] = []
  @Local showAccountPicker: boolean = false
  @Local showKeyboard: boolean = false
  @Local keyboardOffset: number = 300
  
  private accountService = AccountService.getInstance()

  aboutToAppear() {
    this.loadCategories()
    this.loadAccounts()
  }

  // 加载账户列表
  private async loadAccounts(): Promise<void> {
    this.accounts = await this.accountService.getAllAccounts()
    if (this.accounts.length > 0) {
      // 默认选择第一个账户
      this.selectedAccount = this.accounts[0]
    }
  }

  private loadCategories() {
    this.categories = this.billService.getCategories(this.currentType)
    if (this.categories.length > 0) {
      this.selectedCategory = this.categories[0].name
    }
  }

  private onTypeChange(type: BillType) {
    this.currentType = type
    this.loadCategories()
  }

  // 显示键盘动画
  private showKeyboardWithAnimation() {
    if (!this.showKeyboard) {
      this.showKeyboard = true
      animateTo({
        duration: 300,
        curve: Curve.EaseOut
      }, () => {
        this.keyboardOffset = 0
      })
    }
  }

  // 隐藏键盘动画
  private hideKeyboardWithAnimation() {
    if (this.showKeyboard) {
      animateTo({
        duration: 300,
        curve: Curve.EaseIn
      }, () => {
        this.keyboardOffset = 300
      })
      // 延迟隐藏键盘，等待动画完成
      setTimeout(() => {
        this.showKeyboard = false
      }, 300)
    }
  }

  private onNumberInput(num: string) {
    if (num === 'delete') {
      this.amount = this.amount.slice(0, -1)
    } else if (num === 'clear') {
      this.amount = ''
    } else if (num === '.') {
      if (!this.amount.includes('.')) {
        this.amount += num
      }
    } else {
      // 限制小数点后两位
      if (this.amount.includes('.')) {
        const parts = this.amount.split('.')
        if (parts[1].length < 2) {
          this.amount += num
        }
      } else {
        this.amount += num
      }
    }
  }

  private async saveRecord() {
    if (!this.amount || parseFloat(this.amount) <= 0 || !this.selectedAccount) {
      // TODO: 显示提示
      return
    }

    const record = new BillRecord(
      parseFloat(this.amount),
      this.currentType,
      this.selectedCategory,
      this.note,
      this.selectedAccount.id
    )

    const success = await this.billService.addBillRecord(record)
    if (success) {
      console.info('记账成功，桌面卡片数据将自动同步更新')
      this.hideKeyboardWithAnimation()
      // 延迟返回，等待键盘隐藏动画完成
      setTimeout(() => {
        // 返回首页并传递刷新标识
        router.back({
          url: PagePath.INDEX,
          params: {
            shouldRefresh: true
          }
        })
      }, 300)
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()
      
      // 内容区域
      Column({ space: 20 }) {
        // 收支类型切换
        this.buildTypeSelector()
        
        // 金额显示
        this.buildAmountDisplay()
        
        // 分类选择
        this.buildCategorySelector()
        
        // 账户选择
        this.buildAccountSelector()
        
        // 备注输入
        this.buildNoteInput()
        
        // 确认记账按钮
        this.buildConfirmButton()
        
        // 数字键盘已移至覆盖层
      }
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      .onClick(() => {
        // 点击空白区域隐藏键盘和弹窗
        if (this.showKeyboard) {
          this.hideKeyboardWithAnimation()
        }
        // 关闭所有弹窗
        this.showCategoryPicker = false
        this.showAccountPicker = false
      })
      
      // 数字键盘覆盖层
      if (this.showKeyboard) {
        Stack({ alignContent: Alignment.Bottom }) {
          // 半透明遮罩
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.3)')
            .onClick(() => {
              this.hideKeyboardWithAnimation()
            })
          
          // 键盘容器
           Column({ space: 8 }) {
            // 第一行
            Row({ space: 8 }) {
              this.buildKeyboardButton('1')
              this.buildKeyboardButton('2')
              this.buildKeyboardButton('3')
            }
            
            // 第二行
            Row({ space: 8 }) {
              this.buildKeyboardButton('4')
              this.buildKeyboardButton('5')
              this.buildKeyboardButton('6')
            }
            
            // 第三行
            Row({ space: 8 }) {
              this.buildKeyboardButton('7')
              this.buildKeyboardButton('8')
              this.buildKeyboardButton('9')
            }
            
            // 第四行
            Row({ space: 8 }) {
              this.buildKeyboardButton('.')
              this.buildKeyboardButton('0')
              this.buildKeyboardButton('删除', 'delete')
            }
            
            // 第五行 - 确认按钮
            Row({ space: 8 }) {
              Button('清空')
                .width('30%')
                .height(48)
                .fontSize(16)
                .backgroundColor($r('app.color.card_background'))
                .fontColor($r('app.color.text_secondary'))
                .borderRadius(8)
                .onClick(() => {
                  this.onNumberInput('clear')
                })
              
              Button('确认记账')
                .width('65%')
                .height(48)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .backgroundColor($r('app.color.primary_color'))
                .fontColor(Color.White)
                .borderRadius(8)
                .onClick(() => {
                  this.saveRecord()
                })
            }
          }
           .width('100%')
           .padding(16)
           .backgroundColor($r('app.color.card_background'))
           .borderRadius({ topLeft: 16, topRight: 16 })
           .translate({ y: this.keyboardOffset })
           .alignSelf(ItemAlign.End)
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
        .zIndex(999)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
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
      
      Text($r('app.string.add_record'))
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      Blank()
      
      Text('')
        .width(32)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.card_background'))
  }

  // 构建收支类型切换
  @Builder
  buildTypeSelector() {
    Row() {
      Button($r('app.string.expense'))
        .width('48%')
        .height(40)
        .fontSize(16)
        .backgroundColor(this.currentType === BillType.EXPENSE ? $r('app.color.expense_color') : $r('app.color.card_background'))
        .fontColor(this.currentType === BillType.EXPENSE ? Color.White : $r('app.color.text_primary'))
        .onClick(() => {
          this.onTypeChange(BillType.EXPENSE)
        })
      
      Blank()
      
      Button($r('app.string.income'))
        .width('48%')
        .height(40)
        .fontSize(16)
        .backgroundColor(this.currentType === BillType.INCOME ? $r('app.color.income_color') : $r('app.color.card_background'))
        .fontColor(this.currentType === BillType.INCOME ? Color.White : $r('app.color.text_primary'))
        .onClick(() => {
          this.onTypeChange(BillType.INCOME)
        })
    }
    .width('100%')
  }

  // 构建金额显示
  @Builder
  buildAmountDisplay() {
    Column({ space: 8 }) {
      Text('金额')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      Row() {
        Text('¥')
          .fontSize(32)
          .fontColor($r('app.color.text_primary'))
        
        Text(this.amount || '0')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(8)
    .onClick(() => {
      this.showKeyboardWithAnimation()
    })
  }

  // 构建分类选择
  @Builder
  buildCategorySelector() {
    Column({ space: 8 }) {
      Text('分类')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 8 }) {
        Stack() {
          Text(this.getCategoryIcon(this.selectedCategory))
            .fontSize(20)
          
          // 颜色指示器
          if (this.selectedCategory) {
            Circle({ width: 8, height: 8 })
              .fill(this.getCategoryColor(this.selectedCategory))
              .stroke(Color.White)
              .strokeWidth(1)
              .position({ x: 16, y: 16 })
          }
        }
        .width(24)
        .height(24)
        
        Text(this.selectedCategory || '请选择分类')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        
        Text('>')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.background_color'))
      .borderRadius(8)
      .onClick(() => {
          // 确保其他弹窗都关闭
          this.showAccountPicker = false
          // 显示分类选择弹窗
          this.showCategoryPicker = true
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(8)
    .bindSheet($$this.showCategoryPicker, this.buildCategoryPicker(), {
      height: 400
    })
  }

  // 构建备注输入
  @Builder
  buildNoteInput() {
    Column({ space: 8 }) {
      Text('备注')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      TextInput({ placeholder: '添加备注...', text: $$this.note })
        .fontSize(16)
        .backgroundColor($r('app.color.background_color'))
        .borderRadius(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(8)
  }

  // 构建确认记账按钮
  @Builder
  buildConfirmButton() {
    Button('确认记账')
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor($r('app.color.primary_color'))
      .fontColor(Color.White)
      .borderRadius(8)
      .margin({ top: 16 })
      .onClick(() => {
        this.saveRecord()
      })
  }



  // 构建键盘按钮
  @Builder
  buildKeyboardButton(label: string, value?: string) {
    Button(label)
      .width('30%')
      .height(48)
      .fontSize(18)
      .backgroundColor($r('app.color.card_background'))
      .fontColor($r('app.color.text_primary'))
      .borderRadius(8)
      .onClick(() => {
        this.onNumberInput(value || label)
      })
  }



  // 构建分类选择器
  @Builder
  buildCategoryPicker() {
    Column({ space: 16 }) {
      Text('选择分类')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      Grid() {
        ForEach(this.categories, (category: BillCategory) => {
          GridItem() {
            Column({ space: 8 }) {
              Stack() {
                 Text(category.icon)
                  .fontSize(24)
                
                // 颜色指示器
                Circle({ width: 8, height: 8 })
                  .fill(category.color)
                  .stroke(Color.White)
                  .strokeWidth(1)
                  .position({ x: 20, y: 20 })
              }
              .width(32)
              .height(32)
              
              Text(category.name)
                .fontSize(12)
                .fontColor($r('app.color.text_primary'))
            }
            .width(60)
            .height(60)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.selectedCategory === category.name ? $r('app.color.primary_color') : $r('app.color.background_color'))
            .borderRadius(8)
            .onClick(() => {
              this.selectedCategory = category.name
              this.showCategoryPicker = false
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .width('100%')
    }
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
  }

  // 构建账户选择
  @Builder
  buildAccountSelector() {
    Column({ space: 8 }) {
      Text('账户')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .alignSelf(ItemAlign.Start)
      
      Row({ space: 8 }) {
        Text(this.selectedAccount?.name || '请选择账户')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        
        Text('>')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .padding(12)
      .backgroundColor($r('app.color.background_color'))
      .borderRadius(8)
      .onClick(() => {
          // 确保其他弹窗都关闭
          this.showCategoryPicker = false
          // 显示账户选择弹窗
          this.showAccountPicker = true
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(8)
    .bindSheet($$this.showAccountPicker, this.buildAccountPicker(), {
      height: 300
    })
  }

  // 构建账户选择器
  @Builder
  buildAccountPicker() {
    Column({ space: 16 }) {
      Text('选择账户')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      ForEach(this.accounts, (account: Account) => {
        Row({ space: 12 }) {
          Text(account.name)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          
          Text(`¥${account.balance.toFixed(2)}`)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(16)
        .backgroundColor(this.selectedAccount?.id === account.id ? $r('app.color.primary_color') : $r('app.color.background_color'))
        .borderRadius(8)
        .onClick(() => {
          this.selectedAccount = account
          this.showAccountPicker = false
        })
      })
    }
    .padding(20)
    .backgroundColor($r('app.color.card_background'))
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
    const categoryObj = this.categories.find(cat => cat.name === category)
    return categoryObj?.color || '#FF6B6B'
  }
}