//DBConsole.ets：数据库控制台；最后修改时间：2025年6月5日15:45:41
import { relationalStore } from '@kit.ArkData'; //关系数据库
import { Context } from '@ohos.arkui.UIContext'; //上下文
import { DBConfig, DBTable, StudentInfo } from './Structers'; //自定义数据结构
import call from '@ohos.telephony.call';

/**
 * 数据库控制台，用于数据库添删改查操作
 */
export class DBConsole {
  /**
   * 数据库控制台DBConsole静态实例Instance
   */
  public static Instance: DBConsole = new DBConsole();
  /**
   * 数据库表dbTables
   */
  public dbTables: DBTable[] = [];
  /**
   * 数据库连接对象rdbStore
   */
  private rdbStore: relationalStore.RdbStore | null = null;

  /**
   * 构造函数
   */
  constructor() {
    try {
      //1.dbTables数组加入学员信息数据库表
      this.dbTables.push(DBTable.getStudentDBTableInstance())

      //2.打开/创建数据库（连接对象rdbStore）
      this.getRDBStore((success: boolean) => {
        if (success) //若已成功初始化数据库（连接对象rdbStore）
        {
          //3.遍历执行dbTables的建表SQL语句createTableSQLString
          for (let i = 0; i < this.dbTables.length; i++) {
            //执行建表SQL语句createTableSQLString
            this.executeSQLStringSync(this.dbTables[i].createTableSQLString)
          }
          if (this.dbTables.length > 0) {
            console.info(`成功加载数据库表 ${this.dbTables.length} 个！`)
          } else {
            console.error('错误#57100：未加载数据库表，dbTables数据库表长度为 0 ！')
            AlertDialog.show({ message: '错误#57100：未加载数据库表，dbTables数据库表长度为 0 ！' })
            return;
          }
        }
      })
    } catch (e) {
      console.error('错误#57101' + e)
      AlertDialog.show({ message: '错误#57101' + e })
    }
  }

  /**
   * 打开/创建关系型数据库，如果不存在数据库表，创建它
   * @param callback回调函数
   */
  public getRDBStore(callback: Function) {
    try {
      //检测回调函数是否为空
      if (!callback || typeof callback === 'undefined' || callback === undefined) {
        console.error('错误#57102：getDBStore方法的参数callback（回调函数）不能为空！')
        AlertDialog.show({ message: '错误#57102：getDBStore方法的参数callback（回调函数）不能为空！' })
        return;
      }
      //若rdbStore不为空（已初始化）
      if (this.rdbStore !== null) {
        console.info('数据库连接对象rdbStore已加载！')
        callback(true);
      } else { //rdbStore为空（尚未初始化）
        //获取上下文Context（提供应用环境信息，如文件路径、权限等）
        let context: Context = getContext(this) as Context;
        // 打开/创建关系型数据库
        relationalStore.getRdbStore(context, DBConfig.STUDENT_STORE_CONFIG, (error, rdbStore) => {
          if (error) { //若操作出现错误异常，警告提示后返回
            console.error(error.message);
            AlertDialog.show({ message: error.message })
            callback(false)
            return;
          }
          //若返回数据库连接对象rdbStore
          if (rdbStore !== null) {
            //rdbStore赋值给rdbStore
            this.rdbStore = rdbStore;
            console.info('数据库连接对象rdbStore已加载！')
            callback(true);
          }
        });
      }
    } catch (e) {
      console.error('错误#57103：' + e)
      AlertDialog.show({ message: '错误#57103：' + e })
    }
  }

  /**
   * 异步执行SQL语句
   * @param sqlString SQL语句
   */
  public executeSQLString(sqlString: string) {
    try {
      //若数据库连接对象rdbStore不为空
      if (this.rdbStore !== null) {
        //若sqlString不为空
        if (sqlString) {
          //执行SQL语句sqlString
          this.rdbStore.execute(sqlString)
          console.info(`异步执行SQL语句 1 条`)
        }
      }
    } catch (e) {
      console.error('错误#57104：' + e)
      AlertDialog.show({ message: '错误#57104：' + e })
    }
  }

  /**
   * 同步执行SQL语句
   * @param sqlString SQL语句
   */
  public executeSQLStringSync(sqlString: string) {
    try {
      //若数据库连接对象rdbStore不为空
      if (this.rdbStore !== null) {
        //若sqlStrings不为空
        if (sqlString) {
          //执行SQL语句sqlString
          this.rdbStore.executeSync(sqlString)
          console.info(`（同步）执行SQL语句 1 条`)
        }
      }
    } catch (e) {
      console.error('错误#57105：' + e)
      AlertDialog.show({ message: '错误#57105：' + e })
    }
  }

  /**
   * 获取在StudentInfo数据库表中的所有对象的数组
   * @param callback 回调函数
   */
  public getAllStudents(callback: Function) {
    try { //检测回调函数是否为空
      if (!callback || typeof callback === 'undefined' || callback === undefined) {
        console.error('错误#57106：getAllStudents方法的参数callback（回调函数）不能为空！')
        AlertDialog.show({ message: '错误#57106：getAllStudents方法的参数callback（回调函数）不能为空！' })
        return;
      }
      //获得学员信息数据库表名称
      let tableName = DBTable.TABLE_NAME_STUDENT;
      //谓词仅为数据库表，表示查询整个数据库表
      let predicates = new relationalStore.RdbPredicates(tableName);
      //用谓词查询整个数据库表
      this.queryTableSync(this.getDBTable(tableName), predicates,
        (resultSet: relationalStore.ResultSet) => {
          //记录数据库表数据行数
          let rowCount: number = resultSet.rowCount;
          //若行数为0（没有数据行）
          if (rowCount === 0 || typeof rowCount === 'string') {
            console.info(`查询的数据库表【${tableName}】数据行数为【0】!`);
            callback([]); //调用回调函数
          } else {
            //定位到数据行第一行
            resultSet.goToFirstRow();
            //定义返回学员类型数组result
            const results: StudentInfo[] = [];
            //将查询结构数据行逐行赋值给返回数组result
            for (let i = 0; i < rowCount; i++) {
              let tmp = new StudentInfo({
                ID: '',
                姓名: '',
                班级: '',
                年龄: 0,
                照片: undefined,
              });
              tmp.ID = resultSet.getString(resultSet.getColumnIndex('ID'));
              tmp.姓名 = resultSet.getString(resultSet.getColumnIndex('姓名'));
              tmp.班级 = resultSet.getString(resultSet.getColumnIndex('班级'));
              tmp.年龄 = resultSet.getDouble(resultSet.getColumnIndex('年龄'));
              tmp.照片 = resultSet.getBlob(resultSet.getColumnIndex('照片'));
              results[i] = tmp;
              resultSet.goToNextRow(); //定位到下一行
            }
            callback(results); //触发回调函数，参数为返回数组results
          }
        });
    } catch (e) {
      console.error('错误#57107：' + e)
      AlertDialog.show({ message: '错误#57107：' + e })
    }
  }

  /**
   * 获取在StudentInfo数据库表中的指定ID的学员对象
   * @param id 学员ID
   * @param callback 回调函数
   */
  public getStudentByID(id: string, callback: Function) {
    try {
      //检测回调函数是否为空
      if (!callback || typeof callback === 'undefined' || callback === undefined) {
        console.error('错误#57108：getStudentByID方法的参数callback（回调函数）不能为空！')
        AlertDialog.show({ message: '错误#57108：getStudentByID方法的参数callback（回调函数）不能为空！' })
        return;
      }
      //获得学员信息数据库表名称
      let tableName = DBTable.TABLE_NAME_STUDENT;
      //谓词仅为数据库表，表示查询整个数据库表
      let predicates = new relationalStore.RdbPredicates(tableName);
      //谓词加入匹配ID，表示查询ID匹配的结果数据行
      predicates.equalTo('ID', id);
      //用谓词查询数据库表匹配数据行
      this.queryTableSync(this.getDBTable(tableName), predicates,
        (resultSet: relationalStore.ResultSet) => {
          //记录数据库表数据行数
          let rowCount: number = resultSet.rowCount;
          //若行数为0（没有数据行）
          if (rowCount === 0 || typeof rowCount === 'string') {
            console.info(`查询的数据库表【${tableName}】数据行数为【0】!`);
            callback([]); //触发回调函数
          } else {
            resultSet.goToFirstRow(); //定位到数据行第一行
            const results: StudentInfo[] = []; //定义返回学员类型数组result
            //将查询结构数据行逐行赋值给返回数组result
            for (let i = 0; i < rowCount; i++) {
              let tmp = new StudentInfo({
                ID: '',
                姓名: '',
                班级: '',
                年龄: 0,
                照片: undefined,
              });
              tmp.ID = resultSet.getString(resultSet.getColumnIndex('ID'));
              tmp.姓名 = resultSet.getString(resultSet.getColumnIndex('姓名'));
              tmp.班级 = resultSet.getString(resultSet.getColumnIndex('班级'));
              tmp.年龄 = resultSet.getDouble(resultSet.getColumnIndex('年龄'));
              tmp.照片 = resultSet.getBlob(resultSet.getColumnIndex('照片'));
              results[i] = tmp;
              resultSet.goToNextRow(); //定位到下一行
            }
            callback(results); //触发回调函数，参数为返回数组results
          }
        });
    } catch (e) {
      console.error('错误#57109：' + e)
      AlertDialog.show({ message: '错误#57109：' + e })
    }
  }

  /**
   * 同步查询数据库表
   * @param table 数据库表
   * @param predicates 谓词
   * @param callback 回调函数
   */
  private queryTableSync(
    table: DBTable | undefined,
    predicates: relationalStore.RdbPredicates,
    callback: Function) {
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      console.error('错误#57110：queryTable方法的参数callback（回调函数）不能为空！');
      AlertDialog.show({ message: '错误#57110：queryTable方法的参数callback（回调函数）不能为空！' })
      return;
    }
    //若数据库连接对象rdbStore不为空
    if (this.rdbStore) {
      //若数据库表不为空
      if (table) {
        let resultSet: relationalStore.ResultSet | null = null;
        try { //匹配谓词查询数据库表
          resultSet = this.rdbStore.querySync(predicates, table.columns);
          console.info(`成功查询到数据库表【${table.tableName}】数据【${resultSet.rowCount}】行`);
          //触发回调函数
          callback(resultSet);
          //关闭数据流
          resultSet.close();
        } catch (e) {
          console.error('错误#57112：' + e)
          AlertDialog.show({ message: '错误#57112：' + e })
        } finally {
          // 确保结果集被关闭
          if (resultSet) {
            (resultSet as relationalStore.ResultSet)?.close()
            console.info('查询后的结果集已关闭');
          }
        }
      }
    }
  }

  /**
   * 获取数据库表名称对应的DBTable（数据库表）
   * @param tableName 表名称
   * @returns DBTable（数据库表）
   */
  private getDBTable(tableName: string): DBTable | undefined {
    let table: DBTable | undefined = undefined;
    if (this.dbTables && this.dbTables.length > 0) {
      table = this.dbTables[0] //默认第0个数据库表
      //遍历匹配名称的数据库表
      for (let i = 0; i < this.dbTables.length; i++) {
        if (this.dbTables[i].tableName === tableName) {
          table = this.dbTables[i];
          break; //找到一个匹配的表就中断退出循环
        }
      }
    }
    return table;
  }

  /**
   * 用学员StudentInfo对象生成一个ValuesBucket对象
   * @param student 学员StudentInfo对象
   * @returns
   */
  private generateStudentBucket(student: StudentInfo): relationalStore.ValuesBucket {
    let obj: relationalStore.ValuesBucket = {};
    obj.ID = student.ID;
    obj.姓名 = student.姓名;
    obj.班级 = student.班级;
    obj.年龄 = student.年龄;
    if (student.照片 !== undefined
      && student.照片 !== null) {
      obj.照片 = student.照片;
    }
    return obj;
  }

  /**
   * 插入添加一个StudentInfo对象到数据库表StudentInfo
   * @param student 学员信息StudentInfo对象
   * @param callback 回调函数
   */
  public insertStudent(student: StudentInfo, callback?: Function) {
    //检测回调函数是否为空
    if (!callback || typeof callback === 'undefined' || callback === undefined) {
      console.error('错误#57113：insertStudent方法的参数callback（回调函数）不能为空！')
      AlertDialog.show({ message: '错误#57113：insertStudent方法的参数callback（回调函数）不能为空！' })
      return;
    }
    try {
      //定义值容器对象
      let data: relationalStore.ValuesBucket;
      //学员对象转为值容器对象
      data = this.generateStudentBucket(student);
      //值容器对象赋值
      const valueBucket: relationalStore.ValuesBucket = data;
      //添加数据操作
      if (this.rdbStore) {
        if (this.dbTables) {
          //开始添加操作
          let resNumber = this.rdbStore.insertSync(this.dbTables[0].tableName, valueBucket);
          //若未发生异常（操作成功）
          //记录成功和返回数据
          console.info(`添加学员操作【成功】`);
          //触发回调函数，true表示操作成功
          callback(true);
        }
      }
    } catch (e) {
      //触发回调函数，false表示操作失败
      callback(false);
      console.error('错误#57114：' + e)
      AlertDialog.show({ message: '错误#57114：' + e })
    }
  }

  /**
   * 生成新的学员ID字符串
   * @param callback
   */
  public generateStudentID(callback: Function) {
    try {
      //查询获取所有学员信息
      this.getAllStudents((resultSet: StudentInfo[]) => {
        //定义ID的数字编号
        let startIDIndex = resultSet.length;
        // 判断resultSet数组中是否有元素的 ID 属性等于 'startIDIndex.toString'
        let hasTheID = resultSet.some(student => student.ID === startIDIndex.toString());
        while (hasTheID) { //如果已有这个ID值
          //ID编号自增
          startIDIndex++;
          //重新判断resultSet数组中是否已有指定ID值
          hasTheID = resultSet.some(student => student.ID === startIDIndex.toString());
        }
        //生成的ID数字编号转字符串赋值到ID
        let ID = startIDIndex.toString();
        //回调函数传回生成的ID
        callback(ID);
      });
    } catch (e) {
      console.error('错误#57115：' + e)
      AlertDialog.show({ message: '错误#57115：' + e })
    }
  }

  /**
   * @param predicates 删除在数据库表中的行
   * @param callback  回调函数（回传操作是否成功）
   */
  deleteData(predicates: relationalStore.RdbPredicates, callback?: Function) {
    try {
      if (this.rdbStore) { //若数据库连接对象不为空
        this.rdbStore.deleteSync(predicates); //调用删除数据行API（同步方式）
        if (callback) { //若回调函数不为空
          callback(true); //触发回调函数，回传操作成功标志
        }
        console.info('删除操作【成功】');
      }
    } catch (e) { //捕获异常e
      if (callback) { //若回调函数不为空
        callback(false); //触发回调函数，回传操作失败标志
      }
      console.error('错误#57116：' + e)
      AlertDialog.show({ message: '错误#57116：' + e })
    }
  }

  /**
   * 删除在数据库表StudentInfo中匹配ID的对象
   * @param id  学员ID
   * @param callback  回调函数（回传操作是否成功）
   */
  public deleteStudent(id: string, callback?: Function) {
    try {
      let predicates = new relationalStore.RdbPredicates(DBTable.TABLE_NAME_STUDENT); //谓词指向数据库表
      predicates.equalTo('ID', id); //谓词指向匹配ID值的行
      this.deleteData(predicates, callback); //删除相应数据行
      console.info('删除学员操作【成功】');
    } catch (e) { //捕获异常e
      if (callback) { //若回调函数不为空
        callback(false); //触发回调函数，回传操作失败标志
      }
      console.error('错误#57117：' + e)
      AlertDialog.show({ message: '错误#57117：' + e })
    }
  }

  /**
   * 清空数据库库表中的数据行
   * @param tableName 数据库表名
   * @param callback  回调函数（回传操作是否成功）
   */
  public clearTable(tableName: string, callback?: Function) {
    try {
      let predicates = new relationalStore.RdbPredicates(tableName); //谓词指向数据库表
      this.deleteData(predicates, callback); //删除相应数据行
      console.info('清空数据库表操作【成功】');
    } catch (e) { //捕获异常e
      if (callback) { //若回调函数不为空
        callback(false); //触发回调函数，回传操作失败标志
      }
      console.error('错误#57118：' + e)
      AlertDialog.show({ message: '错误#57118：' + e })
    }
  }

  /**
   * @param predicates  谓词
   * @param data  ValuesBucket对象
   * @param callback  回调函数（回传操作是否成功）
   */
  updateData(predicates: relationalStore.RdbPredicates, data: relationalStore.ValuesBucket, callback?: Function) {
    try {
      let valueBucket: relationalStore.ValuesBucket = data; //声明数据库数据结构变量
      if (this.rdbStore) { //若数据库连接对象不为空
        this.rdbStore.updateSync(valueBucket, predicates); //调用修改数据行数据API（同步方式）
        if (callback) { //若回调函数不为空
          callback(true); //触发回调函数，回传操作成功标志
        }
        console.info('修改数据操作【成功】');
      }
    } catch (e) { //捕获异常e
      if (callback) { //若回调函数不为空
        callback(false); //触发回调函数，回传操作失败标志
      }
      console.error('错误#57119：' + e)
      AlertDialog.show({ message: '错误#57119：' + e })
    }
  }

  /**
   * 修改在数据库表StudentInfo中的对象
   * @param id 学员ID值
   * @param student 学员信息StudentInfo实例对象
   * @param callback  回调函数（回传操作是否成功）
   */
  public updateStudent(id: string, student: StudentInfo, callback?: Function) {
    try {
      let data: relationalStore.ValuesBucket; //声明数据库数据结构变量
      data = this.generateStudentBucket(student); //student对象转ValuesBucket对象
      let predicates = new relationalStore.RdbPredicates(DBTable.TABLE_NAME_STUDENT); //谓词指向数据库表
      predicates.equalTo('ID', id); //谓词指向匹配ID值的行
      this.updateData(predicates, data, callback); //修改相应数据行
      if (callback) { //若回调函数不为空
        callback(true); //触发回调函数，回传操作成功标志
      }
      console.info('修改学员信息操作【成功】');
    } catch (e) { //捕获异常e
      if (callback) { //若回调函数不为空
        callback(false); //触发回调函数，回传操作失败标志
      }
      console.error('错误#57120：' + e)
      AlertDialog.show({ message: '错误#57120：' + e })
    }
  }
}


