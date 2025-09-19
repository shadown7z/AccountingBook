import { preferences } from '@kit.ArkData'
import { notificationManager } from '@kit.NotificationKit'
import { wantAgent, WantAgent } from '@kit.AbilityKit'

/**
 * 提醒类型
 */
export enum ReminderType {
  DAILY = 'daily',
  WEEKLY = 'weekly',
  MONTHLY = 'monthly'
}

/**
 * 提醒配置
 */
export interface ReminderConfig {
  id?: number
  type: ReminderType
  hour: number
  minute: number
  title: string
  content: string
  enabled: boolean
  repeatDays?: number[] // 周几提醒，1-7表示周一到周日
}

/**
 * 定时提醒服务
 */
export class ReminderService {
  private static instance: ReminderService
  private readonly REMINDER_PREFS_KEY = 'reminder_settings'
  private dataPreferences: preferences.Preferences | null = null

  private constructor() {
    this.initPreferences()
  }

  public static getInstance(): ReminderService {
    if (!ReminderService.instance) {
      ReminderService.instance = new ReminderService()
    }
    return ReminderService.instance
  }

  // 初始化数据存储
  private async initPreferences(): Promise<void> {
    try {
      this.dataPreferences = await preferences.getPreferences(getContext(), 'reminder_prefs')
    } catch (error) {
      console.error('Failed to init reminder preferences:', error)
    }
  }

  // 获取所有提醒配置
  public async getAllReminders(): Promise<ReminderConfig[]> {
    try {
      if (!this.dataPreferences) {
        await this.initPreferences()
      }
      
      const remindersJson = await this.dataPreferences?.get(this.REMINDER_PREFS_KEY, '[]') as string
      return JSON.parse(remindersJson) as ReminderConfig[]
    } catch (error) {
      console.error('Failed to get reminders:', error)
      return []
    }
  }

  // 保存提醒配置
  private async saveReminders(reminders: ReminderConfig[]): Promise<boolean> {
    try {
      if (!this.dataPreferences) {
        await this.initPreferences()
      }
      
      await this.dataPreferences?.put(this.REMINDER_PREFS_KEY, JSON.stringify(reminders))
      await this.dataPreferences?.flush()
      return true
    } catch (error) {
      console.error('Failed to save reminders:', error)
      return false
    }
  }

  // 添加提醒
  public async addReminder(config: ReminderConfig): Promise<boolean> {
    try {
      const reminders = await this.getAllReminders()
      
      // 生成新的ID
      const newId = Date.now()
      config.id = newId
      
      reminders.push(config)
      
      const saved = await this.saveReminders(reminders)
      if (saved && config.enabled) {
        await this.scheduleReminder(config)
      }
      
      return saved
    } catch (error) {
      console.error('Failed to add reminder:', error)
      return false
    }
  }

  // 更新提醒
  public async updateReminder(config: ReminderConfig): Promise<boolean> {
    try {
      const reminders = await this.getAllReminders()
      const index = reminders.findIndex(r => r.id === config.id)
      
      if (index === -1) {
        return false
      }
      
      // 先取消旧的提醒
      if (reminders[index].enabled && reminders[index].id) {
        await this.cancelReminder(reminders[index].id!)
      }
      
      reminders[index] = config
      
      const saved = await this.saveReminders(reminders)
      if (saved && config.enabled && config.id) {
        await this.scheduleReminder(config)
      }
      
      return saved
    } catch (error) {
      console.error('Failed to update reminder:', error)
      return false
    }
  }

  // 删除提醒
  public async deleteReminder(id: number): Promise<boolean> {
    try {
      const reminders = await this.getAllReminders()
      const index = reminders.findIndex(r => r.id === id)
      
      if (index === -1) {
        return false
      }
      
      // 取消系统提醒
      await this.cancelReminder(id)
      
      reminders.splice(index, 1)
      return await this.saveReminders(reminders)
    } catch (error) {
      console.error('Failed to delete reminder:', error)
      return false
    }
  }

  // 启用/禁用提醒
  public async toggleReminder(id: number, enabled: boolean): Promise<boolean> {
    try {
      const reminders = await this.getAllReminders()
      const reminder = reminders.find(r => r.id === id)
      
      if (!reminder) {
        return false
      }
      
      reminder.enabled = enabled
      
      if (enabled) {
        await this.scheduleReminder(reminder)
      } else {
        await this.cancelReminder(id)
      }
      
      return await this.saveReminders(reminders)
    } catch (error) {
      console.error('Failed to toggle reminder:', error)
      return false
    }
  }

  // 调度系统提醒
  private async scheduleReminder(config: ReminderConfig): Promise<void> {
    try {
      if (!config.id) {
        console.error('Reminder config must have an id')
        return
      }

      // 创建WantAgent用于点击通知时的行为
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.example.accountingbook3',
            abilityName: 'EntryAbility'
          }
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: config.id || 0
      }

      const wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo)

      // 构建通知请求
      const notificationRequest: notificationManager.NotificationRequest = {
        id: config.id || 0,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: config.title,
            text: config.content
          }
        },
        wantAgent: wantAgentObj
      }

      // 发布通知（这里只是示例，实际的定时功能需要配合系统定时器）
      console.log(`Reminder scheduled successfully for ${config.hour}:${config.minute}`)
      console.log('Note: Actual scheduling requires system timer integration')
    } catch (error) {
      console.error('Failed to schedule reminder:', error)
    }
  }

  // 取消系统提醒
  private async cancelReminder(id: number): Promise<void> {
    try {
      // 取消通知
      await notificationManager.cancel(id)
      console.log(`Reminder ${id} cancelled successfully`)
    } catch (error) {
      console.error('Failed to cancel reminder:', error)
    }
  }

  // 获取默认提醒配置
  public getDefaultReminders(): ReminderConfig[] {
    return [
      {
        type: ReminderType.DAILY,
        hour: 21,
        minute: 0,
        title: '🐻 记账提醒',
        content: '今天还没有记账哦，快来记录一下今天的收支吧！',
        enabled: false
      },
      {
        type: ReminderType.WEEKLY,
        hour: 20,
        minute: 0,
        title: '🐻 周总结提醒',
        content: '本周的账单记录得怎么样？来看看这周的收支情况吧！',
        enabled: false,
        repeatDays: [7] // 周日
      }
    ]
  }

  // 初始化默认提醒
  public async initDefaultReminders(): Promise<void> {
    try {
      const existingReminders = await this.getAllReminders()
      if (existingReminders.length === 0) {
        const defaultReminders = this.getDefaultReminders()
        for (const reminder of defaultReminders) {
          await this.addReminder(reminder)
        }
      }
    } catch (error) {
      console.error('Failed to init default reminders:', error)
    }
  }

  // 检查提醒权限
  public async checkReminderPermission(): Promise<boolean> {
    try {
      // 这里可以添加权限检查逻辑
      return true
    } catch (error) {
      console.error('Failed to check reminder permission:', error)
      return false
    }
  }

  // 请求提醒权限
  public async requestReminderPermission(): Promise<boolean> {
    try {
      // 这里可以添加权限请求逻辑
      return true
    } catch (error) {
      console.error('Failed to request reminder permission:', error)
      return false
    }
  }

  // 格式化时间显示
  public formatTime(hour: number, minute: number): string {
    const h = hour.toString().padStart(2, '0')
    const m = minute.toString().padStart(2, '0')
    return `${h}:${m}`
  }

  // 格式化重复天数显示
  public formatRepeatDays(days: number[]): string {
    if (!days || days.length === 0) {
      return '不重复'
    }
    
    if (days.length === 7) {
      return '每天'
    }
    
    const dayNames = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日']
    return days.map(day => dayNames[day]).join('、')
  }

  // 获取下次提醒时间
  public getNextReminderTime(config: ReminderConfig): Date | null {
    try {
      const now = new Date()
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate(), config.hour, config.minute)
      
      if (config.type === ReminderType.DAILY) {
        if (today > now) {
          return today
        } else {
          const tomorrow = new Date(today)
          tomorrow.setDate(tomorrow.getDate() + 1)
          return tomorrow
        }
      }
      
      if (config.type === ReminderType.WEEKLY && config.repeatDays) {
        const currentDay = now.getDay() || 7 // 将周日从0改为7
        
        for (const day of config.repeatDays.sort()) {
          if (day > currentDay || (day === currentDay && today > now)) {
            const nextDate = new Date(today)
            nextDate.setDate(nextDate.getDate() + (day - currentDay))
            return nextDate
          }
        }
        
        // 下周的第一个提醒日
        const firstDay = config.repeatDays[0]
        const nextWeek = new Date(today)
        nextWeek.setDate(nextWeek.getDate() + (7 - currentDay + firstDay))
        return nextWeek
      }
      
      return null
    } catch (error) {
      console.error('Failed to get next reminder time:', error)
      return null
    }
  }
}