import * as bodyParser from 'body-parser';
import * as express from 'express';
import * as morgan from 'morgan';
import { MainRouter } from './routes/main-router';

class App {

  public app: express.Application;
  public router: MainRouter = new MainRouter();

  constructor() {
    this.app = express();
    this.config();
    this.router.attach(this.app);
  }

  private config(): void {
    this.app.use(bodyParser.json());
    // support application/x-www-form-urlencoded post data
    this.app.use(bodyParser.urlencoded({ extended: false }));

    this.app.use(morgan('combined'));


    this.app.use(require('sanitize').middleware);
  }

}

export default new App().app;
