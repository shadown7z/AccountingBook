import { router } from '@kit.ArkUI'
import { ReminderService, ReminderConfig, ReminderType } from '../service/ReminderService'

@Entry
@ComponentV2
struct ReminderPage {
  @Local reminders: ReminderConfig[] = []
  @Local showAddDialog: boolean = false
  @Local showEditDialog: boolean = false
  @Local showTimePickerDialog: boolean = false
  @Local editingReminder: ReminderConfig | null = null
  @Local selectedHour: number = 21
  @Local selectedMinute: number = 0
  @Local isTimePickerForEdit: boolean = false
  
  // 新增提醒的临时数据
  @Local newReminderTitle: string = ''
  @Local newReminderContent: string = ''
  @Local newReminderType: ReminderType = ReminderType.DAILY
  @Local newReminderHour: number = 21
  @Local newReminderMinute: number = 0
  @Local newReminderDays: number[] = []
  
  private reminderService = ReminderService.getInstance()

  async aboutToAppear() {
    await this.loadReminders()
  }

  // 加载提醒列表
  private async loadReminders() {
    this.reminders = await this.reminderService.getAllReminders()
  }

  // 添加提醒
  private async addReminder() {
    const config: ReminderConfig = {
      type: this.newReminderType,
      hour: this.newReminderHour,
      minute: this.newReminderMinute,
      title: this.newReminderTitle || '🐻 记账提醒',
      content: this.newReminderContent || '今天还没有记账哦，快来记录一下今天的收支吧！',
      enabled: true,
      repeatDays: this.newReminderType === ReminderType.WEEKLY ? this.newReminderDays : undefined
    }
    
    const success = await this.reminderService.addReminder(config)
    if (success) {
      await this.loadReminders()
      this.resetNewReminderData()
      this.showAddDialog = false
    }
  }

  // 重置新增提醒数据
  private resetNewReminderData() {
    this.newReminderTitle = ''
    this.newReminderContent = ''
    this.newReminderType = ReminderType.DAILY
    this.newReminderHour = 21
    this.newReminderMinute = 0
    this.newReminderDays = []
  }

  // 切换提醒状态
  private async toggleReminder(reminder: ReminderConfig) {
    if (reminder.id) {
      const success = await this.reminderService.toggleReminder(reminder.id, !reminder.enabled)
      if (success) {
        await this.loadReminders()
      }
    }
  }

  // 删除提醒
  private async deleteReminder(reminder: ReminderConfig) {
    if (reminder.id) {
      const success = await this.reminderService.deleteReminder(reminder.id)
      if (success) {
        await this.loadReminders()
      }
    }
  }

  // 编辑提醒
  private editReminder(reminder: ReminderConfig) {
    this.editingReminder = {
      id: reminder.id,
      type: reminder.type,
      hour: reminder.hour,
      minute: reminder.minute,
      title: reminder.title,
      content: reminder.content,
      enabled: reminder.enabled,
      repeatDays: reminder.repeatDays
    }
    this.showEditDialog = true
  }

  // 保存编辑的提醒
  private async saveEditedReminder() {
    if (this.editingReminder) {
      const success = await this.reminderService.updateReminder(this.editingReminder)
      if (success) {
        await this.loadReminders()
        this.showEditDialog = false
        this.editingReminder = null
      }
    }
  }

  // 选择时间
  private selectTime(isForEdit: boolean = false) {
    this.isTimePickerForEdit = isForEdit
    if (isForEdit && this.editingReminder) {
      this.selectedHour = this.editingReminder.hour
      this.selectedMinute = this.editingReminder.minute
    } else {
      this.selectedHour = this.newReminderHour
      this.selectedMinute = this.newReminderMinute
    }
    this.showTimePickerDialog = true
  }

  // 确认时间选择
  private confirmTimeSelection() {
    if (this.isTimePickerForEdit && this.editingReminder) {
      this.editingReminder.hour = this.selectedHour
      this.editingReminder.minute = this.selectedMinute
    } else {
      this.newReminderHour = this.selectedHour
      this.newReminderMinute = this.selectedMinute
    }
    this.showTimePickerDialog = false
  }

  // 切换周几选择
  private toggleWeekDay(day: number, isForEdit: boolean = false) {
    if (isForEdit && this.editingReminder) {
      if (!this.editingReminder.repeatDays) {
        this.editingReminder.repeatDays = []
      }
      const index = this.editingReminder.repeatDays.indexOf(day)
      if (index > -1) {
        this.editingReminder.repeatDays.splice(index, 1)
      } else {
        this.editingReminder.repeatDays.push(day)
      }
    } else {
      const index = this.newReminderDays.indexOf(day)
      if (index > -1) {
        this.newReminderDays.splice(index, 1)
      } else {
        this.newReminderDays.push(day)
      }
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .width(20)
            .height(20)
            .fontColor(['#666666'])
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })

        Text('提醒设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button() {
          SymbolGlyph($r('sys.symbol.plus'))
            .width(20)
            .height(20)
            .fontColor(['#007AFF'])
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showAddDialog = true
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.white'))

      // 提醒列表
      if (this.reminders.length > 0) {
        List() {
          ForEach(this.reminders, (reminder: ReminderConfig) => {
            ListItem() {
              Row() {
                Column() {
                  Text(reminder.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  
                  Text(reminder.content)
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                  
                  Row() {
                    Text(this.reminderService.formatTime(reminder.hour, reminder.minute))
                      .fontSize(14)
                      .fontColor($r('app.color.brand_primary'))
                      .fontWeight(FontWeight.Medium)
                    
                    Text('•')
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ left: 8, right: 8 })
                    
                    Text(this.reminderService.formatRepeatDays(reminder.repeatDays || []))
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                  }
                  .margin({ top: 8 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Row() {
                  // 编辑按钮
                  Button() {
                    SymbolGlyph($r('sys.symbol.pencil_line'))
                      .width(16)
                      .height(16)
                      .fontColor(['#666666'])
                  }
                  .width(32)
                  .height(32)
                  .backgroundColor(Color.Transparent)
                  .onClick(() => {
                    this.editReminder(reminder)
                  })
                  .margin({ right: 8 })

                  // 开关
                  Toggle({ type: ToggleType.Switch, isOn: reminder.enabled })
                    .width(44)
                    .height(24)
                    .selectedColor($r('app.color.brand_primary'))
                    .onChange((isOn: boolean) => {
                      this.toggleReminder(reminder)
                    })
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor($r('app.color.white'))
            }
            .swipeAction({ end: this.deleteButton(reminder) })
          })
        }
        .layoutWeight(1)
        .divider({
          strokeWidth: 1,
          color: $r('app.color.divider'),
          startMargin: 16,
          endMargin: 16
        })
      } else {
        // 空状态
        Column() {
          Text('🐻')
            .fontSize(48)
            .margin({ bottom: 16 })
          
          Text('还没有设置提醒')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 8 })
          
          Text('点击右上角 + 号添加提醒')
            .fontSize(14)
            .fontColor($r('app.color.text_tertiary'))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .bindSheet($$this.showAddDialog, this.addReminderDialog(), {
      height: 500,
      dragBar: true,
      backgroundColor: $r('app.color.white')
    })
    .bindSheet($$this.showEditDialog, this.editReminderDialog(), {
      height: 500,
      dragBar: true,
      backgroundColor: $r('app.color.white')
    })
    .bindSheet($$this.showTimePickerDialog, this.timePickerDialog(), {
      height: 400,
      dragBar: true,
      backgroundColor: $r('app.color.white')
    })
  }

  // 删除按钮
  @Builder
  deleteButton(reminder: ReminderConfig) {
    Button() {
      Text('删除')
        .fontSize(14)
        .fontColor(Color.White)
    }
    .width(60)
    .height('100%')
    .backgroundColor('#FF3B30')
    .onClick(() => {
      this.deleteReminder(reminder)
    })
  }

  // 添加提醒弹窗
  @Builder
  addReminderDialog() {
    Column() {
      Text('添加提醒')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20, bottom: 20 })

      Column() {
        // 标题输入
        TextInput({ placeholder: '提醒标题', text: $$this.newReminderTitle })
          .fontSize(16)
          .backgroundColor($r('app.color.input_background'))
          .borderRadius(8)
          .padding(12)
          .margin({ bottom: 12 })

        // 内容输入
        TextInput({ placeholder: '提醒内容', text: $$this.newReminderContent })
          .fontSize(16)
          .backgroundColor($r('app.color.input_background'))
          .borderRadius(8)
          .padding(12)
          .margin({ bottom: 12 })

        // 提醒类型选择
        Row() {
          Text('提醒类型')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
          
          Blank()
          
          Row() {
            Button('每天')
              .fontSize(14)
              .fontColor(this.newReminderType === ReminderType.DAILY ? Color.White : $r('app.color.brand_primary'))
              .backgroundColor(this.newReminderType === ReminderType.DAILY ? $r('app.color.brand_primary') : Color.Transparent)
              .border({
                width: 1,
                color: $r('app.color.brand_primary')
              })
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => {
                this.newReminderType = ReminderType.DAILY
              })
            
            Button('每周')
              .fontSize(14)
              .fontColor(this.newReminderType === ReminderType.WEEKLY ? Color.White : $r('app.color.brand_primary'))
              .backgroundColor(this.newReminderType === ReminderType.WEEKLY ? $r('app.color.brand_primary') : Color.Transparent)
              .border({
                width: 1,
                color: $r('app.color.brand_primary')
              })
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .margin({ left: 8 })
              .onClick(() => {
                this.newReminderType = ReminderType.WEEKLY
              })
          }
        }
        .width('100%')
        .margin({ bottom: 12 })

        // 周几选择（仅周提醒显示）
        if (this.newReminderType === ReminderType.WEEKLY) {
          Column() {
            Text('选择星期')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .alignSelf(ItemAlign.Start)
              .margin({ bottom: 8 })
            
            Row() {
              ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string, index: number) => {
                Button(day)
                  .fontSize(14)
                  .fontColor(this.newReminderDays.includes(index + 1) ? Color.White : $r('app.color.text_primary'))
                  .backgroundColor(this.newReminderDays.includes(index + 1) ? $r('app.color.brand_primary') : $r('app.color.input_background'))
                  .borderRadius(20)
                  .width(32)
                  .height(32)
                  .onClick(() => {
                    this.toggleWeekDay(index + 1)
                  })
                  .margin({ right: index < 6 ? 8 : 0 })
              })
            }
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
          .margin({ bottom: 12 })
        }

        // 时间选择
        Row() {
          Text('提醒时间')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
          
          Blank()
          
          Button(this.reminderService.formatTime(this.newReminderHour, this.newReminderMinute))
            .fontSize(16)
            .fontColor($r('app.color.brand_primary'))
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.selectTime(false)
            })
        }
        .width('100%')
        .margin({ bottom: 20 })
      }
      .padding(20)

      // 按钮区域
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.input_background'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.showAddDialog = false
            this.resetNewReminderData()
          })
        
        Button('确定')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(8)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.addReminder()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
  }

  // 编辑提醒弹窗
  @Builder
  editReminderDialog() {
    if (this.editingReminder) {
      Column() {
        Text('编辑提醒')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20, bottom: 20 })

        Column() {
          // 标题输入
          TextInput({ placeholder: '提醒标题', text: $$this.editingReminder.title })
            .fontSize(16)
            .backgroundColor($r('app.color.input_background'))
            .borderRadius(8)
            .padding(12)
            .margin({ bottom: 12 })

          // 内容输入
          TextInput({ placeholder: '提醒内容', text: $$this.editingReminder.content })
            .fontSize(16)
            .backgroundColor($r('app.color.input_background'))
            .borderRadius(8)
            .padding(12)
            .margin({ bottom: 12 })

          // 时间选择
          Row() {
            Text('提醒时间')
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
            
            Blank()
            
            Button(this.reminderService.formatTime(this.editingReminder.hour, this.editingReminder.minute))
              .fontSize(16)
              .fontColor($r('app.color.brand_primary'))
              .backgroundColor(Color.Transparent)
              .onClick(() => {
                this.selectTime(true)
              })
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 周几选择（仅周提醒显示）
          if (this.editingReminder.type === ReminderType.WEEKLY) {
            Column() {
              Text('选择星期')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 8 })
              
              Row() {
                ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string, index: number) => {
                  Button(day)
                    .fontSize(14)
                    .fontColor((this.editingReminder?.repeatDays?.includes(index + 1)) ? Color.White : $r('app.color.text_primary'))
                    .backgroundColor((this.editingReminder?.repeatDays?.includes(index + 1)) ? $r('app.color.brand_primary') : $r('app.color.input_background'))
                    .borderRadius(20)
                    .width(32)
                    .height(32)
                    .onClick(() => {
                      this.toggleWeekDay(index + 1, true)
                    })
                    .margin({ right: index < 6 ? 8 : 0 })
                })
              }
              .justifyContent(FlexAlign.SpaceBetween)
            }
            .width('100%')
            .margin({ bottom: 20 })
          }
        }
        .padding(20)

        // 按钮区域
        Row() {
          Button('取消')
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.input_background'))
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => {
              this.showEditDialog = false
              this.editingReminder = null
            })
          
          Button('保存')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor($r('app.color.brand_primary'))
            .borderRadius(8)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.saveEditedReminder()
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })
      }
      .width('100%')
    }
  }

  // 时间选择弹窗
  @Builder
  timePickerDialog() {
    Column() {
      Text('选择时间')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20, bottom: 20 })

      TimePicker({
        selected: new Date(2024, 0, 1, this.selectedHour, this.selectedMinute)
      })
        .onChange((value: TimePickerResult) => {
          this.selectedHour = value.hour || 0
          this.selectedMinute = value.minute || 0
        })
        .margin({ bottom: 20 })

      // 按钮区域
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.input_background'))
          .borderRadius(8)
          .layoutWeight(1)
          .onClick(() => {
            this.showTimePickerDialog = false
          })
        
        Button('确定')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(8)
          .layoutWeight(1)
          .margin({ left: 12 })
          .onClick(() => {
            this.confirmTimeSelection()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
    .padding(20)
  }
}