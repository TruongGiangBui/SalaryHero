
export default class  ResultObj {
    Errorcode: string
    ErrorMessage: string
    Data: any;
    constructor(row: any) {
        this.Errorcode = row.Errorcode;
        this.ErrorMessage = row.ErrorMessage;
        this.Data=row.Data
    }
}