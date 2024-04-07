
export default class  Result {
    Errorcode: string
    ErrorMessage: string
    Data: Array<any>;
    constructor(row: any) {
        this.Errorcode = row.Errorcode;
        this.ErrorMessage = row.ErrorMessage;
        this.Data=row.Data
    }
}