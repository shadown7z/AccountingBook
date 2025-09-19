import { BillService } from './BillService'
import { BillRecord, BillType } from '../model/BillRecord'
import { fileIo } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'

export class ExportService {
  private static instance: ExportService
  private billService = BillService.getInstance()

  private constructor() {}

  public static getInstance(): ExportService {
    if (!ExportService.instance) {
      ExportService.instance = new ExportService()
    }
    return ExportService.instance
  }

  // 导出为CSV格式
  public async exportToCSV(records: BillRecord[], fileName: string = 'bills.csv'): Promise<boolean> {
    try {
      const csvContent = this.generateCSVContent(records)
      return await this.saveFile(csvContent, fileName, 'text/csv')
    } catch (error) {
      console.error('CSV导出失败:', error)
      return false
    }
  }

  // 导出为Excel格式（实际为CSV，但可用Excel打开）
  public async exportToExcel(records: BillRecord[], fileName: string = 'bills.xlsx'): Promise<boolean> {
    try {
      // 由于HarmonyOS限制，这里生成CSV格式但使用.xlsx扩展名
      // 用户可以用Excel打开CSV文件
      const csvContent = this.generateCSVContent(records)
      return await this.saveFile(csvContent, fileName.replace('.xlsx', '.csv'), 'text/csv')
    } catch (error) {
      console.error('Excel导出失败:', error)
      return false
    }
  }

  // 生成CSV内容
  private generateCSVContent(records: BillRecord[]): string {
    const headers = ['日期', '时间', '类型', '分类', '金额', '备注']
    const csvRows = [headers.join(',')]

    records.forEach(record => {
      const row = [
        record.date,
        this.formatTime(record.createTime),
        record.type === BillType.INCOME ? '收入' : '支出',
        record.category,
        record.amount.toString(),
        record.note || ''
      ]
      // 处理包含逗号的字段，用双引号包围
      const escapedRow = row.map(field => {
        if (field.includes(',') || field.includes('"') || field.includes('\n')) {
          return `"${field.replace(/"/g, '""')}"`
        }
        return field
      })
      csvRows.push(escapedRow.join(','))
    })

    return csvRows.join('\n')
  }

  // 保存文件
  private async saveFile(content: string, fileName: string, mimeType: string): Promise<boolean> {
    try {
      // 使用文件选择器让用户选择保存位置
      const documentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      documentSaveOptions.fileSuffixChoices = ['.csv']
      
      const documentViewPicker = new picker.DocumentViewPicker()
      const uris = await documentViewPicker.save(documentSaveOptions)
      
      if (uris && uris.length > 0) {
        const file = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(file.fd, content)
        fileIo.closeSync(file)
        return true
      }
      return false
    } catch (error) {
      console.error('文件保存失败:', error)
      return false
    }
  }

  // 格式化时间
  private formatTime(timeStr: string): string {
    const date = new Date(timeStr)
    return `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`
  }

  // 获取指定日期范围的记录
  public getRecordsByDateRange(startDate: string, endDate: string): BillRecord[] {
    const allRecords = this.billService.getBillRecords()
    return allRecords.filter(record => {
      return record.date >= startDate && record.date <= endDate
    })
  }

  // 获取指定类型的记录
  public getRecordsByType(type: BillType): BillRecord[] {
    const allRecords = this.billService.getBillRecords()
    return allRecords.filter(record => record.type === type)
  }

  // 获取指定分类的记录
  public getRecordsByCategory(category: string): BillRecord[] {
    const allRecords = this.billService.getBillRecords()
    return allRecords.filter(record => record.category === category)
  }

  // 生成导出统计信息
  public generateExportSummary(records: BillRecord[]): string {
    const totalIncome = records
      .filter(r => r.type === BillType.INCOME)
      .reduce((sum, r) => sum + r.amount, 0)
    
    const totalExpense = records
      .filter(r => r.type === BillType.EXPENSE)
      .reduce((sum, r) => sum + r.amount, 0)
    
    const balance = totalIncome - totalExpense
    
    return `导出统计:\n` +
           `记录总数: ${records.length}笔\n` +
           `总收入: ¥${totalIncome.toFixed(2)}\n` +
           `总支出: ¥${totalExpense.toFixed(2)}\n` +
           `净收支: ¥${balance.toFixed(2)}`
  }
}