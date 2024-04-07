import { EmployeesRouter } from './employees-router';
import { SalaryRouter } from './slary-router';
export class MainRouter {
  
  public attach(app): void {
    this.addRoutes(app);
    this.addErrorHandler(app);
  }

  private addRoutes(app) {
    const employeesRouter = new EmployeesRouter();
    const salaryRouter = new SalaryRouter();
    employeesRouter.attach(app);
    salaryRouter.attach(app);
  }

  private addErrorHandler(app) {
    // catch 404 and forward to error handler
    app.use(function (req, res, next) {
      const err = new Error('Not Found');
      (<any>err).status = 404;
      next(err);
    });

    app.use(function (err, req, res, next) {
      console.log(err.stack);
      res.status(err.status || 500);
      res.json({
        'meta': {
          code: err.status,
          message: err.message
        }
      });
    });
  }
}
