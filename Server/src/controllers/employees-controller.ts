import { Request, Response } from 'express';
import DatabaseConnection from '../DatabaseService'
import Result from '../models/result'
import ResultObj from '../models/result-obj'
export class EmployeesController {
  public dbConnect: DatabaseConnection = new DatabaseConnection();
  public getEmployees = async (req: Request, res: Response) => {
    // const result = await execute(`SELECT * FROM employees`, [], true)
    let result = await this.dbConnect.execute_proc("BEGIN prc_get_employees(:p_REFCURSOR,:p_userid,:p_err_code,:p_err_param);end;", {
      "p_userid": "ALL"
    });

    res.json(result);
  }

  public getEmployeeById = async (req: Request, res: Response) => {
    console.log(req.params.employeeId)
    let result = await this.dbConnect.execute_proc("BEGIN prc_get_employees(:p_REFCURSOR,:p_userid,:p_err_code,:p_err_param);end;", {
      "p_userid": req.params.employeeId
    });
    let rs = new Result(result);
    if (rs.Data.length > 0) {
      res.json(new ResultObj({
        Errorcode: rs.Errorcode,
        ErrorMessage: rs.ErrorMessage,
        Data: rs.Data[0]
      }));
    } else {
      res.json(new ResultObj({
        Errorcode: '-1',
        ErrorMessage: 'User not found',
        Data: null
      }));
    }

  }
}
