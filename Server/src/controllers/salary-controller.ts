import { Request, Response } from 'express';
import DatabaseConnection from '../DatabaseService'
import Result from '../models/result'
import ResultObj from '../models/result-obj'
export class SalaryController {
  private dbConnect: DatabaseConnection = new DatabaseConnection();
  
  public getBalance = async (req: Request, res: Response) => {
    console.log(req.params.salaryId)
    let result = await this.dbConnect.execute_proc("BEGIN prc_get_balance(:p_REFCURSOR,:p_userid,:p_err_code,:p_err_param);end;", {
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
  public withdraw = async (req: Request, res: Response) => {
    console.log(req.body)
    let result = await this.dbConnect.execute_proc("BEGIN prc_withdraw(:p_userid,:p_amount,:p_err_code,:p_err_param);end;", {
      "p_userid": req.params.employeeId,
      "p_amount": req.body.amount
    });
    let rs = new Result(result);
    res.json(rs)
  }
}
