// 分类管理页面
import { HMRouter } from '@hadss/hmrouter'
import { BillService } from '../service/BillService'
import { BillCategory, BillType } from '../model/BillRecord'
import { PagePath } from '../constants/PagePath'

@Entry
@HMRouter({ pageUrl: PagePath.CATEGORY_MANAGE })
@ComponentV2
export struct CategoryManagePage {
  private billService = BillService.getInstance()
  @Local categories: BillCategory[] = []
  @Local currentType: BillType = BillType.EXPENSE
  @Local showAddDialog: boolean = false
  @Local showEditDialog: boolean = false
  @Local editingCategory: BillCategory | null = null
  @Local newCategoryName: string = ''
  @Local newCategoryIcon: string = '📝'
  @Local newCategoryColor: string = '#FF6B6B'
  
  // 常用图标列表
  private readonly commonIcons: string[] = [
    '🍽️', '🚗', '🛒', '🎮', '🏥', '📚', '🏠', '💰',
    '🎁', '📈', '💼', '📝', '☕', '🎬', '👕', '💊',
    '⛽', '📱', '💡', '🎵', '🏃', '✈️', '🎂', '🌟'
  ]
  
  // 常用颜色列表
  private readonly commonColors: string[] = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
    '#DDA0DD', '#98D8C8', '#F7DC6F', '#58D68D', '#F8C471',
    '#85C1E9', '#BB8FCE', '#82E0AA', '#F1948A', '#85C1E9'
  ]

  aboutToAppear() {
    this.loadCategories()
  }

  // 加载分类数据
  private loadCategories() {
    this.categories = this.billService.getCategories(this.currentType)
  }

  build() {
    Column() {
      // 顶部导航栏
      this.buildNavigationBar()
      
      // 类型切换标签
      this.buildTypeSelector()
      
      // 分类列表
      this.buildCategoryList()
      
      // 添加按钮
      this.buildAddButton()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background_color'))
    .bindSheet($$this.showAddDialog, this.addCategoryDialog, {
      height: 400,
      dragBar: true
    })
    .bindSheet($$this.showEditDialog, this.editCategoryDialog, {
      height: 400,
      dragBar: true
    })
  }

  // 构建导航栏
  @Builder
  buildNavigationBar() {
    Row() {
      Button('返回')
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .fontColor($r('app.color.primary_color'))
        .onClick(() => {
          // 返回上一页
        })
      
      Text('分类管理')
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

  // 构建类型选择器
  @Builder
  buildTypeSelector() {
    Row() {
      Button('支出')
        .type(ButtonType.Normal)
        .backgroundColor(this.currentType === BillType.EXPENSE ? $r('app.color.primary_color') : Color.Transparent)
        .fontColor(this.currentType === BillType.EXPENSE ? Color.White : $r('app.color.text_secondary'))
        .borderRadius(20)
        .layoutWeight(1)
        .onClick(() => {
          this.currentType = BillType.EXPENSE
          this.loadCategories()
        })
      
      Button('收入')
        .type(ButtonType.Normal)
        .backgroundColor(this.currentType === BillType.INCOME ? $r('app.color.primary_color') : Color.Transparent)
        .fontColor(this.currentType === BillType.INCOME ? Color.White : $r('app.color.text_secondary'))
        .borderRadius(20)
        .layoutWeight(1)
        .onClick(() => {
          this.currentType = BillType.INCOME
          this.loadCategories()
        })
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor($r('app.color.background_color'))
  }

  // 构建分类列表
  @Builder
  buildCategoryList() {
    if (this.categories.length > 0) {
      List({ space: 8 }) {
        ForEach(this.categories, (category: BillCategory) => {
          ListItem() {
            this.buildCategoryItem(category)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8 })
    } else {
      Column({ space: 16 }) {
        Text('🐻')
          .fontSize(48)
        
        Text('暂无分类')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
        
        Text('快去添加第一个分类吧~')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }

  // 构建分类项
  @Builder
  buildCategoryItem(category: BillCategory) {
    Row({ space: 12 }) {
      // 分类图标和颜色
      Stack() {
        Text(category.icon)
          .fontSize(24)
          .width(48)
          .height(48)
          .textAlign(TextAlign.Center)
          .backgroundColor($r('app.color.icon_background'))
          .borderRadius(24)
        
        // 颜色指示器
        Circle({ width: 12, height: 12 })
          .fill(category.color)
          .position({ x: 36, y: 36 })
          .border({ width: 2, color: Color.White })
      }
      .width(48)
      .height(48)
      
      // 分类信息
      Column({ space: 4 }) {
        Row() {
          Text(category.name)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          
          if (category.isDefault) {
            Text('默认')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor($r('app.color.tag_background'))
              .borderRadius(10)
          }
        }
        .width('100%')
        
        Text(category.type === BillType.EXPENSE ? '支出分类' : '收入分类')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 操作按钮
      if (!category.isDefault) {
        Row({ space: 8 }) {
          Button('编辑')
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.primary_color'))
            .fontColor(Color.White)
            .fontSize(12)
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onClick(() => {
              this.editingCategory = category
              this.newCategoryName = category.name
              this.newCategoryIcon = category.icon
              this.newCategoryColor = category.color
              this.showEditDialog = true
            })
          
          Button('删除')
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.error_color'))
            .fontColor(Color.White)
            .fontSize(12)
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onClick(() => {
              this.deleteCategory(category)
            })
        }
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .shadow({
      radius: 4,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 1
    })
  }

  // 构建添加按钮
  @Builder
  buildAddButton() {
    Button('添加分类')
      .type(ButtonType.Normal)
      .backgroundColor($r('app.color.primary_color'))
      .fontColor(Color.White)
      .fontSize(16)
      .borderRadius(24)
      .width('100%')
      .height(48)
      .margin({ left: 16, right: 16, bottom: 16 })
      .onClick(() => {
        this.newCategoryName = ''
        this.newCategoryIcon = '📝'
        this.showAddDialog = true
      })
  }

  // 添加分类对话框
  @Builder
  addCategoryDialog() {
    Column({ space: 20 }) {
      Text('添加分类')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      // 分类名称输入
      Column({ space: 8 }) {
        Text('分类名称')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        TextInput({ placeholder: '请输入分类名称', text: $$this.newCategoryName })
          .fontSize(16)
          .borderRadius(8)
          .backgroundColor($r('app.color.input_background'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      
      // 图标选择
      Column({ space: 8 }) {
        Text('选择图标')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        Grid() {
          ForEach(this.commonIcons, (icon: string) => {
            GridItem() {
              Text(icon)
                .fontSize(24)
                .width(48)
                .height(48)
                .textAlign(TextAlign.Center)
                .backgroundColor(this.newCategoryIcon === icon ? $r('app.color.primary_color') : $r('app.color.icon_background'))
                .borderRadius(24)
                .onClick(() => {
                  this.newCategoryIcon = icon
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(120)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      
      // 颜色选择
      Column({ space: 8 }) {
        Text('选择颜色')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        Grid() {
          ForEach(this.commonColors, (color: string) => {
            GridItem() {
              Circle({ width: 36, height: 36 })
                .fill(color)
                .border({
                  width: this.newCategoryColor === color ? 3 : 1,
                  color: this.newCategoryColor === color ? '#333333' : '#E0E0E0'
                })
                .onClick(() => {
                  this.newCategoryColor = color
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(80)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      
      // 颜色选择
      Column({ space: 8 }) {
        Text('选择颜色')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        Grid() {
          ForEach(this.commonColors, (color: string) => {
            GridItem() {
              Circle({ width: 32, height: 32 })
                .fill(color)
                .stroke(this.newCategoryColor === color ? $r('app.color.primary_color') : Color.Transparent)
                .strokeWidth(this.newCategoryColor === color ? 3 : 0)
                .onClick(() => {
                  this.newCategoryColor = color
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(60)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      
      // 操作按钮
      Row({ space: 12 }) {
        Button('取消')
          .type(ButtonType.Normal)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .onClick(() => {
            this.showAddDialog = false
          })
        
        Button('确定')
          .type(ButtonType.Normal)
          .backgroundColor($r('app.color.primary_color'))
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.addCategory()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
  }

  // 编辑分类对话框
  @Builder
  editCategoryDialog() {
    Column({ space: 20 }) {
      Text('编辑分类')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      
      // 分类名称输入
      Column({ space: 8 }) {
        Text('分类名称')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        TextInput({ placeholder: '请输入分类名称', text: $$this.newCategoryName })
          .fontSize(16)
          .borderRadius(8)
          .backgroundColor($r('app.color.input_background'))
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      
      // 图标选择
      Column({ space: 8 }) {
        Text('选择图标')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        
        Grid() {
          ForEach(this.commonIcons, (icon: string) => {
            GridItem() {
              Text(icon)
                .fontSize(24)
                .width(48)
                .height(48)
                .textAlign(TextAlign.Center)
                .backgroundColor(this.newCategoryIcon === icon ? $r('app.color.primary_color') : $r('app.color.icon_background'))
                .borderRadius(24)
                .onClick(() => {
                  this.newCategoryIcon = icon
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(120)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      
      // 操作按钮
      Row({ space: 12 }) {
        Button('取消')
          .type(ButtonType.Normal)
          .backgroundColor($r('app.color.button_secondary'))
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .onClick(() => {
            this.showEditDialog = false
          })
        
        Button('确定')
          .type(ButtonType.Normal)
          .backgroundColor($r('app.color.primary_color'))
          .fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => {
            this.updateCategory()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
  }

  // 添加分类
  private async addCategory() {
    if (!this.newCategoryName.trim()) {
      // 显示提示
      return
    }

    const newCategory = new BillCategory(
      this.newCategoryName.trim(),
      this.newCategoryIcon,
      this.currentType,
      false,
      this.newCategoryColor
    )

    const success = await this.billService.addCategory(newCategory)
    if (success) {
      this.loadCategories()
      this.showAddDialog = false
      // 显示成功提示
    } else {
      // 显示失败提示
    }
  }

  // 更新分类
  private async updateCategory() {
    if (!this.editingCategory || !this.newCategoryName.trim()) {
      return
    }

    this.editingCategory.name = this.newCategoryName.trim()
    this.editingCategory.icon = this.newCategoryIcon
    this.editingCategory.color = this.newCategoryColor

    const success = await this.billService.updateCategory(this.editingCategory)
    if (success) {
      this.loadCategories()
      this.showEditDialog = false
      this.editingCategory = null
      // 显示成功提示
    } else {
      // 显示失败提示
    }
  }

  // 删除分类
  private async deleteCategory(category: BillCategory) {
    const success = await this.billService.deleteCategory(category.id)
    if (success) {
      this.loadCategories()
      // 显示成功提示
    } else {
      // 显示失败提示
    }
  }
}