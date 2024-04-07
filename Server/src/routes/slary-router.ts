import { Application } from 'express';
import { SalaryController } from '../controllers/salary-controller';

export class SalaryRouter {

  public salaryCtrl: SalaryController = new SalaryController();

  public attach(app: Application): void {
    //Lấy thông tin số dư của nhân viên 
    app.route('/salary/balance/:employeeId')
    .get(this.salaryCtrl.getBalance)
    //Tạm ứng tiền lương
    app.route('/salary/withdraw/:employeeId')
    .post(this.salaryCtrl.withdraw)
  }
}
