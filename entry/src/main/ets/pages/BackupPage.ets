import { HMRouter } from '@hadss/hmrouter'
import { BackupService, BackupResult, RestoreResult, AutoBackupInfo } from '../service/BackupService'
import { PAGE_PATH } from '../constants/PagePath'
import { router } from '@kit.ArkUI'

@Entry
@HMRouter({ pageUrl: PAGE_PATH.BACKUP })
@ComponentV2
export struct BackupPage {
  @Local isLoading: boolean = false
  @Local autoBackupList: AutoBackupInfo[] = []
  @Local showBackupResult: boolean = false
  @Local showRestoreResult: boolean = false
  @Local backupResult: BackupResult | null = null
  @Local restoreResult: RestoreResult | null = null
  @Local showAutoBackupList: boolean = false
  
  private backupService = BackupService.getInstance()
  
  aboutToAppear(): void {
    this.loadAutoBackupList()
  }
  
  // 加载自动备份列表
  async loadAutoBackupList() {
    try {
      this.autoBackupList = await this.backupService.getAutoBackupList()
    } catch (error) {
      console.error('Failed to load auto backup list:', error)
    }
  }
  
  // 手动备份
  async performBackup() {
    this.isLoading = true
    try {
      const result = await this.backupService.backupAllData()
      this.backupResult = result
      this.showBackupResult = true
    } catch (error) {
      this.backupResult = {
        success: false,
        message: `备份失败: ${error.message}`
      }
      this.showBackupResult = true
    } finally {
      this.isLoading = false
    }
  }
  
  // 手动恢复
  async performRestore() {
    this.isLoading = true
    try {
      const result = await this.backupService.restoreData()
      this.restoreResult = result
      this.showRestoreResult = true
      
      if (result.success) {
        // 恢复成功后刷新数据
        setTimeout(() => {
          this.loadAutoBackupList()
        }, 1000)
      }
    } catch (error) {
      this.restoreResult = {
        success: false,
        message: `恢复失败: ${error.message}`
      }
      this.showRestoreResult = true
    } finally {
      this.isLoading = false
    }
  }
  
  // 自动备份
  async performAutoBackup() {
    this.isLoading = true
    try {
      const success = await this.backupService.autoBackup()
      this.backupResult = {
        success,
        message: success ? '自动备份成功' : '自动备份失败'
      }
      this.showBackupResult = true
      
      if (success) {
        // 备份成功后刷新列表
        await this.loadAutoBackupList()
      }
    } catch (error) {
      this.backupResult = {
        success: false,
        message: `自动备份失败: ${error.message}`
      }
      this.showBackupResult = true
    } finally {
      this.isLoading = false
    }
  }
  
  // 恢复自动备份
  async restoreAutoBackup(filePath: string) {
    this.isLoading = true
    try {
      const result = await this.backupService.restoreAutoBackup(filePath)
      this.restoreResult = result
      this.showRestoreResult = true
      this.showAutoBackupList = false
    } catch (error) {
      this.restoreResult = {
        success: false,
        message: `恢复失败: ${error.message}`
      }
      this.showRestoreResult = true
    } finally {
      this.isLoading = false
    }
  }
  
  // 格式化文件大小
  formatFileSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }
  
  // 格式化日期
  formatDate(timestamp: string): string {
    const date = new Date(timestamp)
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
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
          router.back()
        })
        
        Text('数据备份')
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
          // 备份说明
          this.buildBackupInfo()
          
          // 手动备份
          this.buildManualBackup()
          
          // 自动备份
          this.buildAutoBackup()
          
          // 数据恢复
          this.buildDataRestore()
          
          // 自动备份历史
          this.buildAutoBackupHistory()
        }
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.background_secondary'))
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showBackupResult, this.backupResultBuilder, {
      height: 300
    })
    .bindSheet($$this.showRestoreResult, this.restoreResultBuilder, {
      height: 300
    })
    .bindSheet($$this.showAutoBackupList, this.autoBackupListBuilder, {
      height: 500
    })
  }
  
  // 备份说明
  @Builder
  buildBackupInfo() {
    Column() {
      Row() {
        Text('💾')
          .fontSize(20)
          .margin({ right: 12 })
        
        Text('数据备份说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .margin({ bottom: 12 })
      
      Text('• 手动备份：将数据导出到您选择的位置，可用于跨设备迁移')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })
      
      Text('• 自动备份：定期在应用内部创建备份，用于数据恢复')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })
      
      Text('• 建议定期进行备份，确保数据安全')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 手动备份
  @Builder
  buildManualBackup() {
    Column() {
      Text('手动备份')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })
      
      Button('导出备份文件')
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.primary_color'))
        .fontColor(Color.White)
        .borderRadius(8)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.performBackup()
        })
      
      Text('将所有数据导出为JSON文件，可保存到您选择的位置')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 自动备份
  @Builder
  buildAutoBackup() {
    Column() {
      Text('自动备份')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })
      
      Button('立即创建自动备份')
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.success_color'))
        .fontColor(Color.White)
        .borderRadius(8)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.performAutoBackup()
        })
      
      Text('在应用内部创建备份，系统会自动保留最近7个备份文件')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 数据恢复
  @Builder
  buildDataRestore() {
    Column() {
      Text('数据恢复')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 16 })
      
      Button('从文件恢复')
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.warning_color'))
        .fontColor(Color.White)
        .borderRadius(8)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.performRestore()
        })
      
      Text('⚠️ 恢复数据将覆盖当前所有数据，请谨慎操作')
        .fontSize(12)
        .fontColor($r('app.color.warning_color'))
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.background_primary'))
    .borderRadius(12)
  }
  
  // 自动备份历史
  @Builder
  buildAutoBackupHistory() {
    Column() {
      Row() {
        Text('自动备份历史')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        
        Button('查看全部')
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.primary_color'))
          .fontSize(14)
          .onClick(() => {
            this.showAutoBackupList = true
          })
      }
      .width('100%')
      .margin({ bottom: 16 })
      
      if (this.autoBackupList.length > 0) {
        ForEach(this.autoBackupList.slice(0, 3), (backup: AutoBackupInfo) => {
          Row() {
            Column() {
              Text(this.formatDate(backup.timestamp))
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
              Text(`${this.formatFileSize(backup.size)} • v${backup.version}`)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            
            Button('恢复')
              .backgroundColor($r('app.color.primary_color'))
              .fontColor(Color.White)
              .fontSize(12)
              .borderRadius(6)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .enabled(!this.isLoading)
              .onClick(() => {
                this.restoreAutoBackup(backup.filePath)
              })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .borderRadius(8)
          .backgroundColor($r('app.color.background_secondary'))
          .margin({ bottom: 8 })
        })
      } else {
        Text('暂无自动备份记录')
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
  
  // 备份结果弹窗
  @Builder
  backupResultBuilder() {
    Column() {
      Text(this.backupResult?.success ? '✅ 备份成功' : '❌ 备份失败')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      Text(this.backupResult?.message || '')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })
      
      if (this.backupResult?.success && this.backupResult.dataCount) {
        Column() {
          Text(`账单记录: ${this.backupResult.dataCount.bills}条`)
            .fontSize(14)
            .margin({ bottom: 4 })
          Text(`账户信息: ${this.backupResult.dataCount.accounts}个`)
            .fontSize(14)
            .margin({ bottom: 4 })
          Text(`预算设置: ${this.backupResult.dataCount.budgets}个`)
            .fontSize(14)
        }
        .margin({ bottom: 20 })
      }
      
      Button('确定')
        .backgroundColor($r('app.color.primary_color'))
        .fontColor(Color.White)
        .onClick(() => {
          this.showBackupResult = false
        })
    }
    .padding(20)
  }
  
  // 恢复结果弹窗
  @Builder
  restoreResultBuilder() {
    Column() {
      Text(this.restoreResult?.success ? '✅ 恢复成功' : '❌ 恢复失败')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      Text(this.restoreResult?.message || '')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })
      
      if (this.restoreResult?.success && this.restoreResult.dataCount) {
        Column() {
          Text(`恢复账单记录: ${this.restoreResult.dataCount.bills}条`)
            .fontSize(14)
            .margin({ bottom: 4 })
          Text(`恢复账户信息: ${this.restoreResult.dataCount.accounts}个`)
            .fontSize(14)
            .margin({ bottom: 4 })
          Text(`恢复预算设置: ${this.restoreResult.dataCount.budgets}个`)
            .fontSize(14)
            .margin({ bottom: 4 })
          
          if (this.restoreResult.backupDate) {
            Text(`备份时间: ${this.formatDate(this.restoreResult.backupDate)}`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8 })
          }
        }
        .margin({ bottom: 20 })
      }
      
      Button('确定')
        .backgroundColor($r('app.color.primary_color'))
        .fontColor(Color.White)
        .onClick(() => {
          this.showRestoreResult = false
        })
    }
    .padding(20)
  }
  
  // 自动备份列表弹窗
  @Builder
  autoBackupListBuilder() {
    Column() {
      Text('自动备份历史')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 20 })
      
      if (this.autoBackupList.length > 0) {
        Scroll() {
          Column() {
            ForEach(this.autoBackupList, (backup: AutoBackupInfo) => {
              Row() {
                Column() {
                  Text(this.formatDate(backup.timestamp))
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                  Text(`${this.formatFileSize(backup.size)} • v${backup.version}`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                
                Button('恢复')
                  .backgroundColor($r('app.color.primary_color'))
                  .fontColor(Color.White)
                  .fontSize(12)
                  .borderRadius(6)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .enabled(!this.isLoading)
                  .onClick(() => {
                    this.restoreAutoBackup(backup.filePath)
                  })
              }
              .width('100%')
              .padding(12)
              .borderRadius(8)
              .backgroundColor($r('app.color.background_secondary'))
              .margin({ bottom: 8 })
            })
          }
        }
        .layoutWeight(1)
      } else {
        Text('暂无自动备份记录')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }
      
      Button('关闭')
        .backgroundColor($r('app.color.background_secondary'))
        .fontColor($r('app.color.text_primary'))
        .margin({ top: 20 })
        .onClick(() => {
          this.showAutoBackupList = false
        })
    }
    .padding(20)
    .height('100%')
  }
}