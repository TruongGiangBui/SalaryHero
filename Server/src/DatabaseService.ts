// import OracleDB from 'OracleDB';
import * as dotenv from 'dotenv'
dotenv.config()

import * as OracleDB from 'oracledb';
export default class DatabaseConnection {
  private OracleDB = OracleDB;
  private dbConfig = {
    user: 'SALARYHERO',
    password: 'SALARYHERO',
    connectString: "(DESCRIPTION =(ADDRESS = (PROTOCOL = TCP)(HOST=localhost)(PORT = 1521))(CONNECT_DATA =(SERVICE_NAME='ORCLPDB1')))"
  }

  public async init(): Promise<void> {
    await this.connectWithDB()
  }

  public async connectWithDB() {
    return new Promise((resolve, reject) => {
      this.OracleDB.getConnection(this.dbConfig, (err, connection) => {
        if (err) {
          reject(err.message);
        }
        console.log('Connected with Database...');
        resolve(connection);
      });
    });
  }

  public async excecute(SQL) {
    return new Promise((resolve, reject) => {
      this.connectWithDB().then(async (connection: any) => {
        await connection.execute(SQL, [], (err, result) => {
          if (err) {
            reject(err.message);
          }
          resolve(result);
        });
        this.doRelease(connection);
      }).catch(error => {
        console.log(error);
        reject(error);
      });
    });
  }

  public async execute_proc(SQL: String, binds) {
    return new Promise((resolve, reject) => {
      this.connectWithDB().then(async (connection: any) => {
        binds.p_err_code = { dir: OracleDB.BIND_OUT, type: OracleDB.STRING };
        binds.p_err_param = { dir: OracleDB.BIND_OUT, type: OracleDB.STRING };
        if (SQL.includes("p_REFCURSOR")) {
          binds.p_REFCURSOR = { dir: OracleDB.BIND_OUT, type: OracleDB.CURSOR };
        }

        console.log(SQL, binds)
        const result = await connection.execute(
          SQL,
          binds
        );


        if (result.outBinds.p_err_code == 0) {
          let data = [];
          
          if (SQL.includes("p_REFCURSOR")) {
            const rs = result.outBinds.p_REFCURSOR;
            // console.log(rs)
            const cols = rs.metaData;
            let row;
            while ((row = await rs.getRow())) {
              var rowdata = {}
              for (var i = 0; i < cols.length; i++) {
                rowdata[cols[i].name] = row[i];
              }
              data.push(rowdata)
            }
            await rs.close();
          }
          resolve({
            Errorcode: 0,
            ErrorMessage: "SUCCESS",
            Data: data
          });
        } else {
          resolve({
            Errorcode: result.outBinds.p_err_code,
            ErrorMessage: result.outBinds.p_err_param
          });
        }
        this.doRelease(connection);
      }).catch(error => {
        console.log(error);
        resolve({
          Errorcode: '-1',
          ErrorMessage: "SYSTEM ERROR"
        });
      });
    });
  }

  public doRelease(connection) {
    connection.release((err) => {
      if (err)
        console.error(err.message);
      console.log('connection released');
    });
  }
}
