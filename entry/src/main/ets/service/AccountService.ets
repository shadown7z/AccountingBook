/**
 * 账户管理服务
 */
import { relationalStore } from '@kit.ArkData'
import { Account, AccountType, AccountStatistics } from '../model/Account'
import { common } from '@kit.AbilityKit'

export class AccountService {
  private static instance: AccountService
  private rdbStore: relationalStore.RdbStore | null = null
  private context: common.UIAbilityContext | null = null

  private constructor() {}

  static getInstance(): AccountService {
    if (!AccountService.instance) {
      AccountService.instance = new AccountService()
    }
    return AccountService.instance
  }

  // 初始化数据库
  async initDatabase(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: 'accounts.db',
      securityLevel: relationalStore.SecurityLevel.S3
    }

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
      await this.createAccountTable()
      await this.initDefaultAccounts()
    } catch (error) {
      console.error('初始化账户数据库失败:', error)
    }
  }

  // 创建账户表
  private async createAccountTable(): Promise<void> {
    if (!this.rdbStore) return

    const createTableSql = `
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL DEFAULT 0,
        initial_balance REAL DEFAULT 0,
        icon TEXT DEFAULT '',
        color TEXT DEFAULT '',
        is_default INTEGER DEFAULT 0,
        create_time INTEGER NOT NULL,
        update_time INTEGER NOT NULL
      )
    `

    try {
      await this.rdbStore.executeSql(createTableSql)
    } catch (error) {
      console.error('创建账户表失败:', error)
    }
  }

  // 初始化默认账户
  private async initDefaultAccounts(): Promise<void> {
    const accounts = await this.getAllAccounts()
    if (accounts.length === 0) {
      // 创建默认账户
      const defaultAccounts = [
        new Account('现金', AccountType.CASH, 0, '💰', '#4CAF50'),
        new Account('支付宝', AccountType.ALIPAY, 0, '🔵', '#1677FF'),
        new Account('微信钱包', AccountType.WECHAT, 0, '🟢', '#07C160')
      ]

      defaultAccounts[0].isDefault = true // 设置现金为默认账户

      for (const account of defaultAccounts) {
        await this.addAccount(account)
      }
    }
  }

  // 添加账户
  async addAccount(account: Account): Promise<boolean> {
    if (!this.rdbStore) return false

    const insertSql = `
      INSERT INTO accounts (
        name, type, balance, initial_balance, icon, color, is_default, create_time, update_time
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `

    try {
      const now = Date.now()
      await this.rdbStore.executeSql(insertSql, [
        account.name,
        account.type,
        account.balance,
        account.initialBalance,
        account.icon || account.getDefaultIcon(),
        account.color || account.getDefaultColor(),
        account.isDefault ? 1 : 0,
        now,
        now
      ])
      return true
    } catch (error) {
      console.error('添加账户失败:', error)
      return false
    }
  }

  // 获取所有账户
  async getAllAccounts(): Promise<Account[]> {
    if (!this.rdbStore) return []

    const querySql = 'SELECT * FROM accounts ORDER BY is_default DESC, create_time ASC'
    const accounts: Account[] = []

    try {
      const resultSet = await this.rdbStore.querySql(querySql)
      
      while (resultSet.goToNextRow()) {
        const account = new Account()
        account.id = resultSet.getLong(resultSet.getColumnIndex('id'))
        account.name = resultSet.getString(resultSet.getColumnIndex('name'))
        account.type = resultSet.getString(resultSet.getColumnIndex('type')) as AccountType
        account.balance = resultSet.getDouble(resultSet.getColumnIndex('balance'))
        account.initialBalance = resultSet.getDouble(resultSet.getColumnIndex('initial_balance'))
        account.icon = resultSet.getString(resultSet.getColumnIndex('icon'))
        account.color = resultSet.getString(resultSet.getColumnIndex('color'))
        account.isDefault = resultSet.getLong(resultSet.getColumnIndex('is_default')) === 1
        account.createTime = new Date(resultSet.getLong(resultSet.getColumnIndex('create_time')))
        account.updateTime = new Date(resultSet.getLong(resultSet.getColumnIndex('update_time')))
        
        accounts.push(account)
      }
      
      resultSet.close()
    } catch (error) {
      console.error('查询账户失败:', error)
    }

    return accounts
  }

  // 根据ID获取账户
  async getAccountById(id: number): Promise<Account | null> {
    if (!this.rdbStore) return null

    const querySql = 'SELECT * FROM accounts WHERE id = ?'

    try {
      const resultSet = await this.rdbStore.querySql(querySql, [id])
      
      if (resultSet.goToFirstRow()) {
        const account = new Account()
        account.id = resultSet.getLong(resultSet.getColumnIndex('id'))
        account.name = resultSet.getString(resultSet.getColumnIndex('name'))
        account.type = resultSet.getString(resultSet.getColumnIndex('type')) as AccountType
        account.balance = resultSet.getDouble(resultSet.getColumnIndex('balance'))
        account.initialBalance = resultSet.getDouble(resultSet.getColumnIndex('initial_balance'))
        account.icon = resultSet.getString(resultSet.getColumnIndex('icon'))
        account.color = resultSet.getString(resultSet.getColumnIndex('color'))
        account.isDefault = resultSet.getLong(resultSet.getColumnIndex('is_default')) === 1
        account.createTime = new Date(resultSet.getLong(resultSet.getColumnIndex('create_time')))
        account.updateTime = new Date(resultSet.getLong(resultSet.getColumnIndex('update_time')))
        
        resultSet.close()
        return account
      }
      
      resultSet.close()
    } catch (error) {
      console.error('查询账户失败:', error)
    }

    return null
  }

  // 获取默认账户
  async getDefaultAccount(): Promise<Account | null> {
    if (!this.rdbStore) return null

    const querySql = 'SELECT * FROM accounts WHERE is_default = 1 LIMIT 1'

    try {
      const resultSet = await this.rdbStore.querySql(querySql)
      
      if (resultSet.goToFirstRow()) {
        const account = new Account()
        account.id = resultSet.getLong(resultSet.getColumnIndex('id'))
        account.name = resultSet.getString(resultSet.getColumnIndex('name'))
        account.type = resultSet.getString(resultSet.getColumnIndex('type')) as AccountType
        account.balance = resultSet.getDouble(resultSet.getColumnIndex('balance'))
        account.initialBalance = resultSet.getDouble(resultSet.getColumnIndex('initial_balance'))
        account.icon = resultSet.getString(resultSet.getColumnIndex('icon'))
        account.color = resultSet.getString(resultSet.getColumnIndex('color'))
        account.isDefault = true
        account.createTime = new Date(resultSet.getLong(resultSet.getColumnIndex('create_time')))
        account.updateTime = new Date(resultSet.getLong(resultSet.getColumnIndex('update_time')))
        
        resultSet.close()
        return account
      }
      
      resultSet.close()
    } catch (error) {
      console.error('查询默认账户失败:', error)
    }

    return null
  }

  // 更新账户
  async updateAccount(account: Account): Promise<boolean> {
    if (!this.rdbStore) return false

    const updateSql = `
      UPDATE accounts SET 
        name = ?, type = ?, balance = ?, initial_balance = ?, 
        icon = ?, color = ?, is_default = ?, update_time = ?
      WHERE id = ?
    `

    try {
      await this.rdbStore.executeSql(updateSql, [
        account.name,
        account.type,
        account.balance,
        account.initialBalance,
        account.icon,
        account.color,
        account.isDefault ? 1 : 0,
        Date.now(),
        account.id
      ])
      return true
    } catch (error) {
      console.error('更新账户失败:', error)
      return false
    }
  }

  // 更新账户余额
  async updateAccountBalance(accountId: number, amount: number): Promise<boolean> {
    if (!this.rdbStore) return false

    const updateSql = 'UPDATE accounts SET balance = balance + ?, update_time = ? WHERE id = ?'

    try {
      await this.rdbStore.executeSql(updateSql, [amount, Date.now(), accountId])
      return true
    } catch (error) {
      console.error('更新账户余额失败:', error)
      return false
    }
  }

  // 删除账户
  async deleteAccount(id: number): Promise<boolean> {
    if (!this.rdbStore) return false

    const deleteSql = 'DELETE FROM accounts WHERE id = ?'

    try {
      await this.rdbStore.executeSql(deleteSql, [id])
      return true
    } catch (error) {
      console.error('删除账户失败:', error)
      return false
    }
  }

  // 设置默认账户
  async setDefaultAccount(id: number): Promise<boolean> {
    if (!this.rdbStore) return false

    try {
      // 先清除所有默认设置
      await this.rdbStore.executeSql('UPDATE accounts SET is_default = 0')
      // 设置新的默认账户
      await this.rdbStore.executeSql('UPDATE accounts SET is_default = 1 WHERE id = ?', [id])
      return true
    } catch (error) {
      console.error('设置默认账户失败:', error)
      return false
    }
  }

  // 获取账户统计信息
  async getAccountStatistics(): Promise<AccountStatistics> {
    if (!this.rdbStore) return new AccountStatistics()

    const querySql = `
      SELECT 
        COUNT(*) as account_count,
        SUM(balance) as total_balance
      FROM accounts
    `

    try {
      const resultSet = await this.rdbStore.querySql(querySql)
      
      if (resultSet.goToFirstRow()) {
        const accountCount = resultSet.getLong(resultSet.getColumnIndex('account_count'))
        const totalBalance = resultSet.getDouble(resultSet.getColumnIndex('total_balance'))
        
        resultSet.close()
        return new AccountStatistics(totalBalance, 0, 0, accountCount)
      }
      
      resultSet.close()
    } catch (error) {
      console.error('查询账户统计失败:', error)
    }

    return new AccountStatistics()
  }
}