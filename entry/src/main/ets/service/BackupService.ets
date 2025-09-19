import { common } from '@kit.AbilityKit'
import { fileIo } from '@kit.CoreFileKit'
import { picker } from '@kit.CoreFileKit'
import { BillService } from './BillService'
import { AccountService } from './AccountService'
import { BudgetService } from './BudgetService'
import { BillRecord, BillStatistics } from '../model/BillRecord'
import { Account } from '../model/Account'
import { Budget } from '../model/Budget'

// 备份文件信息接口
interface BackupFileInfo {
  name: string
  path: string
  mtime: number
}

// 部分备份数据接口
interface PartialBackupData {
  timestamp?: string
  version?: string
}

/**
 * 数据备份和恢复服务
 */
export class BackupService {
  private static instance: BackupService
  private context: common.UIAbilityContext | null = null
  
  private constructor() {}
  
  static getInstance(): BackupService {
    if (!BackupService.instance) {
      BackupService.instance = new BackupService()
    }
    return BackupService.instance
  }
  
  // 初始化服务
  initService(context: common.UIAbilityContext) {
    this.context = context
  }
  
  // 备份所有数据
  async backupAllData(): Promise<BackupResult> {
    try {
      if (!this.context) {
        throw new Error('Context not initialized')
      }
      
      // 获取所有数据
      const billService = BillService.getInstance()
      const accountService = AccountService.getInstance()
      const budgetService = BudgetService.getInstance()
      
      const backupData: BackupData = {
        version: '1.0',
        timestamp: new Date().toISOString(),
        bills: billService.getBillRecords(),
        accounts: await accountService.getAllAccounts(),
        budgets: await budgetService.getAllBudgets(),
        statistics: billService.getStatistics()
      }
      
      // 生成备份文件名
      const fileName = `accounting_backup_${this.formatDate(new Date())}.json`
      
      // 选择保存位置
      const documentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      documentSaveOptions.fileSuffixChoices = ['.json']
      
      const documentPicker = new picker.DocumentViewPicker()
      const saveResult = await documentPicker.save(documentSaveOptions)
      
      if (saveResult && saveResult.length > 0) {
        const filePath = saveResult[0]
        
        // 写入备份数据
        const backupJson = JSON.stringify(backupData, null, 2)
        const file = fileIo.openSync(filePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(file.fd, backupJson)
        fileIo.closeSync(file)
        
        return {
          success: true,
          message: '数据备份成功',
          filePath: filePath,
          dataCount: {
            bills: backupData.bills.length,
            accounts: backupData.accounts.length,
            budgets: backupData.budgets.length
          }
        }
      } else {
        return {
          success: false,
          message: '用户取消备份操作'
        }
      }
    } catch (error) {
      console.error('Backup failed:', error)
      return {
        success: false,
        message: `备份失败: ${error.message}`
      }
    }
  }
  
  // 恢复数据
  async restoreData(): Promise<RestoreResult> {
    try {
      if (!this.context) {
        throw new Error('Context not initialized')
      }
      
      // 选择备份文件
      const documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.fileSuffixFilters = ['.json']
      
      const documentPicker = new picker.DocumentViewPicker()
      const selectResult = await documentPicker.select(documentSelectOptions)
      
      if (selectResult && selectResult.length > 0) {
        const filePath = selectResult[0]
        
        // 读取备份文件
        const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
        const backupJson = fileIo.readTextSync(file.fd.toString())
        fileIo.closeSync(file)
        
        // 解析备份数据
        const backupData: BackupData = JSON.parse(backupJson)
        
        // 验证备份数据格式
        if (!this.validateBackupData(backupData)) {
          return {
            success: false,
            message: '备份文件格式不正确或已损坏'
          }
        }
        
        // 恢复数据
        await this.performRestore(backupData)
        
        const result: RestoreResult = {
          success: true,
          message: '数据恢复成功',
          dataCount: {
            bills: backupData.bills.length,
            accounts: backupData.accounts.length,
            budgets: backupData.budgets.length
          },
          backupDate: backupData.timestamp
        }
        return result
      } else {
        return {
          success: false,
          message: '用户取消恢复操作'
        }
      }
    } catch (error) {
      console.error('Restore failed:', error)
      const result: RestoreResult = {
        success: false,
        message: `恢复失败: ${error.message}`,
        dataCount: { bills: 0, accounts: 0, budgets: 0 }
      }
      return result
    }
  }
  
  // 自动备份
  async autoBackup(): Promise<boolean> {
    try {
      if (!this.context) {
        return false
      }
      
      // 获取应用内部存储路径
      const filesDir = this.context.filesDir
      const backupDir = `${filesDir}/backup`
      
      // 创建备份目录
      if (!fileIo.accessSync(backupDir)) {
        fileIo.mkdirSync(backupDir)
      }
      
      // 获取所有数据
      const billService = BillService.getInstance()
      const accountService = AccountService.getInstance()
      const budgetService = BudgetService.getInstance()
      
      const backupData: BackupData = {
        version: '1.0',
        timestamp: new Date().toISOString(),
        bills: billService.getBillRecords(),
        accounts: await accountService.getAllAccounts(),
        budgets: await budgetService.getAllBudgets(),
        statistics: billService.getStatistics()
      }
      
      // 生成自动备份文件名
      const fileName = `auto_backup_${this.formatDate(new Date())}.json`
      const filePath = `${backupDir}/${fileName}`
      
      // 写入备份数据
      const backupJson = JSON.stringify(backupData, null, 2)
      const file = fileIo.openSync(filePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(file.fd, backupJson)
      fileIo.closeSync(file)
      
      // 清理旧的自动备份文件（保留最近7个）
      await this.cleanOldBackups(backupDir)
      
      return true
    } catch (error) {
      console.error('Auto backup failed:', error)
      return false
    }
  }
  
  // 获取自动备份列表
  async getAutoBackupList(): Promise<AutoBackupInfo[]> {
    try {
      if (!this.context) {
        return []
      }
      
      const backupDir = `${this.context.filesDir}/backup`
      
      if (!fileIo.accessSync(backupDir)) {
        return []
      }
      
      const files = fileIo.listFileSync(backupDir)
      const backupFiles: AutoBackupInfo[] = []
      
      for (const fileName of files) {
        if (fileName.endsWith('.json') && fileName.startsWith('auto_backup_')) {
          const filePath = `${backupDir}/${fileName}`
          const stat = fileIo.statSync(filePath)
          
          try {
            // 读取备份文件基本信息
            const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
            const content = fileIo.readTextSync(file.fd.toString(), { length: 500 }) // 只读取前500字符
            fileIo.closeSync(file)
            
            const partialData: PartialBackupData = JSON.parse(content.substring(0, content.indexOf('"bills"')))
            
            backupFiles.push({
              fileName,
              filePath,
              timestamp: partialData.timestamp || stat.mtime.toString(),
              size: stat.size,
              version: partialData.version || '1.0'
            })
          } catch (error) {
            console.warn(`Failed to read backup file ${fileName}:`, error)
          }
        }
      }
      
      // 按时间倒序排列
      return backupFiles.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
    } catch (error) {
      console.error('Failed to get auto backup list:', error)
      return []
    }
  }
  
  // 恢复自动备份
  async restoreAutoBackup(filePath: string): Promise<RestoreResult> {
    try {
      // 读取备份文件
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      const backupJson = fileIo.readTextSync(file.fd.toString())
      fileIo.closeSync(file)
      
      // 解析备份数据
      const backupData: BackupData = JSON.parse(backupJson)
      
      // 验证备份数据格式
      if (!this.validateBackupData(backupData)) {
        return {
          success: false,
          message: '备份文件格式不正确或已损坏'
        }
      }
      
      // 恢复数据
      await this.performRestore(backupData)
      
      const result: RestoreResult = {
        success: true,
        message: '自动备份恢复成功',
        dataCount: {
          bills: backupData.bills.length,
          accounts: backupData.accounts.length,
          budgets: backupData.budgets.length
        },
        backupDate: backupData.timestamp
      }
      return result
    } catch (error) {
      console.error('Auto backup restore failed:', error)
      return {
        success: false,
        message: `恢复失败: ${error.message}`
      }
    }
  }
  
  // 验证备份数据格式
  private validateBackupData(data: object | null): boolean {
    if (!data || typeof data !== 'object') {
      return false
    }
    const obj = data as Record<string, string | Array<object>>
    return typeof obj.version === 'string' &&
           typeof obj.timestamp === 'string' &&
           Array.isArray(obj.bills) &&
           Array.isArray(obj.accounts) &&
           Array.isArray(obj.budgets)
  }
  
  // 执行数据恢复
  private async performRestore(backupData: BackupData) {
    const billService = BillService.getInstance()
    const accountService = AccountService.getInstance()
    const budgetService = BudgetService.getInstance()
    
    // 清空现有数据
    // 注意：需要在各个服务类中实现clearAllData方法
    
    // 恢复账户数据
    for (const account of backupData.accounts) {
      const newAccount = new Account(account.name, account.type, account.balance)
      await accountService.addAccount(newAccount)
    }
    
    // 恢复预算数据
    for (const budget of backupData.budgets) {
      await budgetService.addBudget(budget)
    }
    
    // 恢复账单数据
    for (const bill of backupData.bills) {
      await billService.addBillRecord(bill)
    }
  }
  
  // 清理旧的自动备份文件
  private async cleanOldBackups(backupDir: string) {
    try {
      const files = fileIo.listFileSync(backupDir)
      const autoBackupFiles: BackupFileInfo[] = files
        .filter(name => name.startsWith('auto_backup_') && name.endsWith('.json'))
        .map(name => {
          const fileInfo: BackupFileInfo = {
            name: name,
            path: `${backupDir}/${name}`,
            mtime: fileIo.statSync(`${backupDir}/${name}`).mtime
          }
          return fileInfo
        })
        .sort((a, b) => b.mtime - a.mtime)
      
      // 保留最近7个文件，删除其余的
      if (autoBackupFiles.length > 7) {
        const filesToDelete = autoBackupFiles.slice(7)
        for (const file of filesToDelete) {
          fileIo.unlinkSync(file.path)
        }
      }
    } catch (error) {
      console.warn('Failed to clean old backups:', error)
    }
  }
  
  // 格式化日期
  private formatDate(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    return `${year}${month}${day}_${hour}${minute}`
  }
}

// 备份数据接口
export interface BackupData {
  version: string
  timestamp: string
  bills: BillRecord[]
  accounts: Account[]
  budgets: Budget[]
  statistics: BillStatistics
}

// 数据计数接口
export interface DataCount {
  bills: number
  accounts: number
  budgets: number
}

// 备份结果接口
export interface BackupResult {
  success: boolean
  message: string
  filePath?: string
  dataCount?: DataCount
}

// 恢复结果接口
export interface RestoreResult {
  success: boolean
  message: string
  dataCount?: DataCount
  backupDate?: string
}

// 自动备份信息接口
export interface AutoBackupInfo {
  fileName: string
  filePath: string
  timestamp: string
  size: number
  version: string
}