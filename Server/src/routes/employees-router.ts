import { Application } from 'express';
import { EmployeesController } from '../controllers/employees-controller';

export class EmployeesRouter {

  public employeesCtrl: EmployeesController = new EmployeesController();

  public attach(app: Application): void {
    app.route('/employee')
    .get(this.employeesCtrl.getEmployees)

    app.route('/employee/:employeeId')
    .get(this.employeesCtrl.getEmployeeById)
  }
}
