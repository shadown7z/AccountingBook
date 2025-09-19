//Structers.ets：项目数据结构；最后修改时间：2025年6月4日16:33:55
import { relationalStore } from '@kit.ArkData'; //引用关系数据库所在命名空间

/**
 * 数据库配置信息
 */
export class DBConfig {
  /**
   * 学员数据库配置信息
   */
  public static readonly STUDENT_STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'Student.db', //数据库文件名
    securityLevel: relationalStore.SecurityLevel.S2, //安全等级S2
    encrypt: false//加密数据库
  }
}

/**
 * 数据库表
 */
export class DBTable {
  /**
   * 学员信息数据库表名称
   */
  public static readonly TABLE_NAME_STUDENT: string = ' StudentInfoTable'
  /**
   * 学员信息数据库表静态实例
   */
  public static InstanceOfStudentTable: DBTable;
  public tableName: string; //数据库表名称
  public createTableSQLString: string = ''; //创建数据库表的SQL语句字符串
  public columns: Array<string>; //数据库表的所有列项
  /**
   * 数据库表构造函数
   * @param tableName 表名
   * @param createTableSQLString 构建数据库表的SQL语句
   * @param columns 数据库表列项（字符串数组）
   */
  constructor(tableName: string, createTableSQLString: string, columns: Array<string>) {
    this.tableName = tableName;
    this.createTableSQLString = createTableSQLString;
    this.columns = columns;
  }

  /**
   * 获取学员信息DBTable的实例Instance
   * @returns DBTalbe
   */
  public static getStudentDBTableInstance() {
    let tableName = DBTable.TABLE_NAME_STUDENT; // 数据库表名，其他表需替换：TABLE_NAME_STUDENT
    DBTable.InstanceOfStudentTable = new DBTable( // 静态实例，其他表需替换：InstanceOfStudentTable
      tableName,
      'CREATE TABLE IF NOT EXISTS '
        + tableName
        + ' (' +
        'ID TEXT PRIMARY KEY,' + // 其他表需替换：对应列项信息
        '姓名 TEXT, ' +
        '班级 TEXT, ' +
        '年龄 INTEGER, ' +
        '照片 BLOB' +
        ')',
      ['ID', '姓名', '班级', '年龄', '照片']); // 其他表需替换：对应列项名称
    return DBTable.InstanceOfStudentTable; // 静态实例，其他表需替换：InstanceOfStudentTable
  }
}

/**
 * 学员信息接口
 */
export interface IStudentInfo {
  ID: string;
  姓名: string;
  班级: string;
  年龄: number;
  照片?: Uint8Array;
}

/**
 * 学员信息类
 */
export class StudentInfo {
  ID: string;
  姓名: string;
  班级: string;
  年龄: number;
  照片?: Uint8Array;

  constructor(options: IStudentInfo) {
    this.ID = options.ID;
    this.姓名 = options.姓名;
    this.班级 = options.班级;
    this.年龄 = options.年龄;
    this.照片 = options.照片;
  }
}



