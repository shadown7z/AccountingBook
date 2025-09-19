/**
 * 账户管理页面
 */
import { AccountService } from '../service/AccountService'
import { Account, AccountType } from '../model/Account'
import { router } from '@kit.ArkUI'

// 账户类型选项接口
interface AccountTypeOption {
  type: AccountType
  name: string
  icon: string
}

@Entry
@ComponentV2
export struct AccountManagePage {
  @Local accounts: Account[] = []
  @Local showAddDialog: boolean = false
  @Local editingAccount: Account | null = null
  @Local newAccountName: string = ''
  @Local newAccountType: AccountType = AccountType.CASH
  @Local newAccountBalance: string = ''
  
  private accountService = AccountService.getInstance()

  aboutToAppear(): void {
    this.loadAccounts()
  }

  // 加载账户列表
  private async loadAccounts(): Promise<void> {
    this.accounts = await this.accountService.getAllAccounts()
  }

  // 添加账户
  private async addAccount(): Promise<void> {
    if (!this.newAccountName.trim()) {
      return
    }

    const account = new Account(
      this.newAccountName.trim(),
      this.newAccountType,
      parseFloat(this.newAccountBalance) || 0
    )

    const success = await this.accountService.addAccount(account)
    if (success) {
      await this.loadAccounts()
      this.resetForm()
      this.showAddDialog = false
    }
  }

  // 设置默认账户
  private async setDefaultAccount(accountId: number): Promise<void> {
    const success = await this.accountService.setDefaultAccount(accountId)
    if (success) {
      await this.loadAccounts()
    }
  }

  // 删除账户
  private async deleteAccount(accountId: number): Promise<void> {
    const success = await this.accountService.deleteAccount(accountId)
    if (success) {
      await this.loadAccounts()
    }
  }

  // 重置表单
  private resetForm(): void {
    this.newAccountName = ''
    this.newAccountType = AccountType.CASH
    this.newAccountBalance = ''
    this.editingAccount = null
  }

  // 返回上一页
  private goBack(): void {
    router.back()
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildHeader()
      
      // 账户列表
      this.buildAccountList()
      
      // 添加按钮
      this.buildAddButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
    .bindSheet($$this.showAddDialog, this.buildAddAccountDialog, {
      height: 400,
      dragBar: true
    })
  }

  // 构建顶部导航栏
  @Builder
  buildHeader() {
    Row() {
      Image($r('sys.symbol.chevron_left'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.text_primary'))
        .onClick(() => {
          this.goBack()
        })
      
      Text('账户管理')
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
    .backgroundColor($r('app.color.white'))
  }

  // 构建账户列表
  @Builder
  buildAccountList() {
    if (this.accounts.length === 0) {
      Column() {
        Text('🐻')
          .fontSize(48)
          .margin({ bottom: 16 })
        
        Text('还没有账户')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 8 })
        
        Text('点击下方按钮添加第一个账户')
          .fontSize(14)
          .fontColor($r('app.color.text_hint'))
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
      .margin({ top: 60 })
    } else {
      List() {
        ForEach(this.accounts, (account: Account) => {
          ListItem() {
            this.buildAccountItem(account)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ top: 8 })
    }
  }

  // 构建账户项
  @Builder
  buildAccountItem(account: Account) {
    Row() {
      // 账户图标
      Text(account.icon || account.getDefaultIcon())
        .fontSize(24)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .backgroundColor(account.color || account.getDefaultColor())
        .borderRadius(20)
        .fontColor($r('app.color.white'))
      
      // 账户信息
      Column() {
        Row() {
          Text(account.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          
          if (account.isDefault) {
            Text('默认')
              .fontSize(12)
              .fontColor($r('app.color.white'))
              .backgroundColor($r('app.color.primary_color'))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(8)
              .margin({ left: 8 })
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        
        Row() {
          Text(account.getTypeDisplayName())
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          
          Text(`¥${account.balance.toFixed(2)}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(account.balance >= 0 ? $r('app.color.income_color') : $r('app.color.expense_color'))
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
      
      // 操作按钮
      Row() {
        if (!account.isDefault) {
          Button('设为默认')
            .fontSize(12)
            .backgroundColor($r('app.color.primary_color'))
            .borderRadius(12)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .onClick(() => {
              this.setDefaultAccount(account.id)
            })
        }
        
        Button('删除')
          .fontSize(12)
          .backgroundColor($r('app.color.expense_color'))
          .borderRadius(12)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .margin({ left: 8 })
          .onClick(() => {
            this.deleteAccount(account.id)
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.white'))
    .borderRadius(12)
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  // 构建添加按钮
  @Builder
  buildAddButton() {
    Button('添加账户')
      .width('calc(100% - 32px)')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor($r('app.color.primary_color'))
      .borderRadius(24)
      .margin({ left: 16, right: 16, bottom: 32 })
      .onClick(() => {
        this.resetForm()
        this.showAddDialog = true
      })
  }

  // 构建添加账户对话框
  @Builder
  buildAddAccountDialog() {
    Column() {
      Text('添加账户')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 24 })
      
      // 账户名称
      Column() {
        Text('账户名称')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入账户名称', text: this.newAccountName })
          .width('100%')
          .height(44)
          .backgroundColor($r('app.color.input_background'))
          .borderRadius(8)
          .onChange((value: string) => {
            this.newAccountName = value
          })
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 账户类型
      Column() {
        Text('账户类型')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        Row() {
          ForEach([
            { type: AccountType.CASH, name: '现金', icon: '💰' },
            { type: AccountType.ALIPAY, name: '支付宝', icon: '🔵' },
            { type: AccountType.WECHAT, name: '微信', icon: '🟢' },
            { type: AccountType.BANK_CARD, name: '银行卡', icon: '🏦' }
          ], (item: AccountTypeOption) => {
            Column() {
              Text(item.icon)
                .fontSize(20)
                .margin({ bottom: 4 })
              
              Text(item.name)
                .fontSize(12)
                .fontColor(this.newAccountType === item.type ? 
                  $r('app.color.primary_color') : $r('app.color.text_secondary'))
            }
            .width(60)
            .height(60)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.newAccountType === item.type ? 
              $r('app.color.primary_light') : $r('app.color.input_background'))
            .borderRadius(8)
            .border({
              width: this.newAccountType === item.type ? 2 : 0,
              color: $r('app.color.primary_color')
            })
            .onClick(() => {
              this.newAccountType = item.type
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      // 初始余额
      Column() {
        Text('初始余额')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入初始余额', text: this.newAccountBalance })
          .width('100%')
          .height(44)
          .backgroundColor($r('app.color.input_background'))
          .borderRadius(8)
          .type(InputType.Number)
          .onChange((value: string) => {
            this.newAccountBalance = value
          })
      }
      .width('100%')
      .margin({ bottom: 24 })
      
      // 操作按钮
      Row() {
        Button('取消')
          .width('calc(50% - 8px)')
          .height(44)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_primary'))
          .borderRadius(22)
          .onClick(() => {
            this.showAddDialog = false
          })
        
        Button('确定')
          .width('calc(50% - 8px)')
          .height(44)
          .backgroundColor($r('app.color.primary_color'))
          .borderRadius(22)
          .onClick(() => {
            this.addAccount()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .padding(20)
  }
}