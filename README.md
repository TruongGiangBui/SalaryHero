# Salary Project

## Mục lục

[1. Thiết kế cơ sở dữ liệu](#1-thiết-kế-cơ-sở-dữ-liệu)

[2. Xây dựng chương trình](#2-xây-dựng-chương-trình)

[3. Hướng dẫn cài đặt](#3-hướng-dẫn-cài-đặt)

[4. Hướng dẫn test hệ thống](#4-hướng-dẫn-test-hệ-thống)

[5. Kết quả test](#5-kết-quả-test)


## 1. Thiết kế cơ sở dữ liệu
![](./images/Screenshot%202024-04-07%20132028.png)

Database sử dụng: **ORACLE**

Các bảng trong cơ sở dữ liệu 
- **EMPLOYEE:** Lưu thông tin cơ bản của nhân viên, ở đây do chỉ cần dùng để tính lương nên em sẽ chỉ lưu userid, tên và usertype.
    - *USERID:* Mã nhân viên, dùng để định danh nhân viên
    - *FULLNAME:* Tên nhân viên 
    - *USERTYPE:* Kiểu nhân viên (D: daily salary, M: monthly salary)

- **SALARY:** Lưu thông tin mức lương của nhân viên. Mỗi nhân viên có thể có các mức lương khác nhau ở các khoảng [from_date, to_date] khác nhau. Khác khoảng thời gian này không gối lên nhau. Tại một thời điểm tính toán chỉ có một bản ghi lương hợp lệ.
    - *AUTOID:* ID tự sinh
    - *USERID:* Mã nhân viên, dùng để định danh nhân viên
    - *BASE_SALARY:* Mức lương
    - *FROM_DATE:* Mức lương tính từ ngày
    - *EXP_DATE:* Mức lương tính đến ngày

- **TIMESHEET:** Bảng lưu thông tin chấm công của nhân viên. Dữ liệu của bảng này có thể được nhập từ một hệ thống chấm công khác. Mỗi dòng dữ liệu tương ứng với một ngày chấm công của nhân viên tương ứng. 
    - *AUTOID:* ID tự sinh
    - *USERID:* Mã nhân viên, dùng để định danh nhân viên
    - *TS_DATE:* Ngày chấm công
    - *ATTENDANT:* Có đi làm hay không (Y/N)
    - *CALCULATED:* Ngày công đã được tính lương chưa (Y/N)

- **MONTH_SALARY:** Bảng lưu thông tin lương tháng đã tính của nhân viên theo tháng và năm.
    - *AUTOID:* ID tự sinh
    - *USERID:* Mã nhân viên, dùng để định danh nhân viên
    - *BALANCE:* Số tiền lương có được
    - *AVAIL_BALANCE:* Số tiền lương khả dụng có thể rút (Trong phạm vi bài này em không tính thuế/bảo hiểm nên AVAIL_BALANCE sẽ bằng BALANCE)
    - *CALC_MONTH:* Tháng
    - *CALC_YEAR:* Năm

- **JOB_LOGS:** Bảng lưu thông tin thời gian chạy của tiến trình tính toán lương.
    - *AUTOID:* ID tự sinh
    - *JOBNAME:* Tên job
    - *EXECUTE_DATE:* Ngày thực hiện
    - *START_TIME:* Thời gian bắt đầu
    - *END_TIME:* Thời gian kết thúc
    - *LOG_MSG:* Nội dung log

- **CONFIG:** Bảng lưu thông tin các tham số dùng trong hệ thống
    - *CONFIG_KEY:* Tên tham số
    - *CONFIG_VALUE:* Giá trị
- Các giá trị config sử dụng trong bảng CONFIG
    - *PROCESSING:* (Y/N) có đang trong tiến trình tính toán hay không. Nếu PROCESSING='Y' thì không cho người dùng rút tiền.
    - *CURRDATE:* Ngày hiện tại của hệ thống. Để có thể test được nhiều lần trong ngày nên ngày hiện tại sẽ được config vào 1 tham số thay vì lấy sysdate. Sau khi chạy xong JOB tính toán hệ thống sẽ update ngày hiện tại sang ngày hôm sau.
    - *MAXPROCESS:* Số bản ghi được select để xử lý tối đa trong 1 lần. Do lúc tính toán sẽ for loop qua hết các nhân viên để tính toán nên nếu lấy lên hết 1 lần thì khi thực hiện tính toán sẽ xảy ra tràn bộ nhớ.
    - *NUMOFWORKDAY:* Số ngày làm việc trong tháng (không tính T7 CN)

## 2. Xây dựng chương trình
Số lượng bản ghi cần tính toán có thể rất lớn. Để tối ưu thời gian xử lý em sẽ sử dụng JOB gọi vào thủ tục ở database để xử lý dữ liệu tại chỗ thay vì dùng Nodejs lấy dữ liệu lên xử lý ở service. Server nodejs sẽ có vai trò cung cấp các API truy vấn số dư và API rút tiền lương của nhân viên.

### Xử lý dữ liệu ở Database

Tạo JOB [AUTO_CALCULATE_SALARY](Database/5.createJob.sql) chạy vào 12h hằng ngày
```sql
BEGIN
    DBMS_SCHEDULER.create_job (
    job_name => 'AUTO_CALCULATE_SALARY',
    job_type => 'PLSQL_BLOCK',
    job_action => 'BEGIN job_auto_calculate_salary;END;',
    start_date => CURRENT_TIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=0',
    enabled => TRUE);
END;
```

Vào cuối ngày JOB AUTO_CALCULATE_SALARY sẽ tự động gọi thủ tục [JOB_AUTO_CALCULATE_SALARY](Database/PROCEDURES/JOB_AUTO_CALCULATE_SALARY.sql) để thực hiện việc tính toán tiền lương của toàn bộ nhân viên. 
Thủ tục sẽ thực hiện tính toán số dư khả dụng theo tháng đến ngày hiện tại dựa vào số dư khả dụng trước đó, mức lương và trạng thái chấm công của ngày hiện tại.

Nếu ngày hiện tại là ngày đầu tháng, hệ thống sẽ tính xem tháng hiện tại có bao nhiêu ngày làm việc và update vào config NUMOFWORKDAY. Tham số NUMOFWORKDAY phục vụ cho việc tính lương hằng ngày của các nhân viên có lương tính theo tháng.

Để tránh việc xử lý 1 lúc quá nhiều bản ghi gây tràn bộ nhớ thì thủ tục sẽ chạy vòng loop, với mỗi vòng loop sẽ chỉ select số lượng MAXPROCESS nhân viên chưa tính lương để thực hiện tính toán. Sau khi xử lý sẽ cập nhật CALCULATED=Y trong bảng timesheet để đánh dấu là đã xử lý. Vòng lặp chỉ dừng lại khi tất cả nhân viên đều đã được tính lương.

Sau khi tính lương, số dư lương khả dụng của nhân viên được cập nhật vào bảng MONTH_SALARY theo tháng, năm tương ứng.

### Webserver

Webserver cung cấp 2 API:

**API truy vấn số dư khả dụng:** 
```sh
curl --location 'http://localhost:3000/salary/balance/111149'
```
Output:
```json
{
    "Errorcode": 0,
    "ErrorMessage": "SUCCESS",
    "Data": {
        "balance": 7545455,
        "availableBalance": 7545455,
        "userID": 111149
    }
}
```
**API rút tiền từ tiền lương khả dụng:** 

```sh
curl --location 'http://localhost:3000/salary/withdraw/1213' \
--header 'Content-Type: application/json' \
--data '{
    "amount":"100000"
}'
```
Output:
```json
{
    "Errorcode": 0,
    "ErrorMessage": "SUCCESS"
}
```
Để tránh lỗi hệ thống, nếu hệ thống đang thực hiện tính toán thì sẽ không được thực hiện rút tiền lương
```json
{
    "Errorcode": "-1",
    "ErrorMessage": "The system is calculating, please try again later"
}
```
API này sẽ chỉ thực hiện trừ số dư của nhân viên trong bảng MONTH_SALARY. Trong thực tế API này sẽ tích hợp thêm vào các cổng thanh toán để thực hiện chuyển khoản trực tiếp cho nhân viên.

## 3. Hướng dẫn cài đặt

**Yêu cầu:** Oracle DB 19C, Nodejs 16
### Cài đặt database

1. Đăng nhập vào user sys của Oracle DB chạy file [1.createSchema.sql](Database/1.createSchema.sql) để tạo schema SALARYHERO
2. Đăng nhập vào schema SALARYHERO
3. Chạy file [2.createTable](Database/2.createTable.sql) để tạo các bảng và sequence của hệ thống
4. Chạy file [3.insertConfig](Database/3.insertConfig.sql) để insert các tham số config
5. Chạy file [4.createProcedure.sql](Database/4.createProcedure.sql) để tạo các thủ tục chạy job và select dữ liệu
6. Chạy file [5.createJob.sql](Database/5.createJob.sql) để tạo job AUTO_CALCULATE_SALARY chạy vào 0h hằng ngày

### Cài đặt service web

1. cd vào thư mục Server
2. install package
```sh
npm install
```
3. Sửa lại thông tin DB theo DB vừa cài đặt trong file .env
4. Start server
```sh
npm run dev 
```
## 4. Hướng dẫn test hệ thống

### Dump dữ liệu test
Chạy file [6.dumpData.sql](Database/6.dumpData.sql) để tạo bộ dữ liệu test. Tham số v_records là số nhân viên được insert (Hiện tại v_records=10000 có thể thay bằng giá trị khác để test). 

File này sẽ sinh ra số lượng v_records nhân viên trong bảng EMPLOYEE, thông tin tiền lương tương ứng ở bảng SALARY và thông tin chấm công cho tất cả các ngày trong tháng 4/2024 ở bảng TIMESHEET(Các nhân viên đều có các ngày nghỉ và mức lương RANDOM)

Ngày hệ thống được khởi tạo là ngày 01/04/2024

### Test tính toán

Vì JOB chỉ chạy tự động vào 12h đêm hằng ngày nên lúc test có thể test bằng các gọi trực tiếp hàm tính 
```sql
begin 
job_auto_calculate_salary;
end;
```

### Test API 
**API truy vấn số dư khả dụng:** 
```sh
curl --location 'http://localhost:3000/salary/balance/111149'
```
**API rút tiền từ tiền lương khả dụng:**
```sh
curl --location 'http://localhost:3000/salary/withdraw/1213' \
--header 'Content-Type: application/json' \
--data '{
    "amount":"100000"
}'
```

## 5. Kết quả test

### Gọi API lấy số dư của nhân viên 111149 
![](./images/Screenshot%202024-04-07%20233122.png)

### Thông tin nhân viên 111149
```sql
select employees.*, salary.base_salary, timesheet.attendant,timesheet.ts_date
from employees
join timesheet on employees.userid=timesheet.userid
join salary on salary.userid=employees.userid
where  salary.from_date<=to_date('04/04/2024','DD/MM/YYYY')
and salary.exp_date>=to_date('04/04/2024','DD/MM/YYYY')
and timesheet.ts_date=to_date('04/04/2024','DD/MM/YYYY')
and employees.userid='111149';
```
![](./images/Screenshot%202024-04-07%20235140.png)

Nhân viên này có đi làm ngày 04/04/2024 và nhận lương theo tháng với mức lương 83,000,000 

### Thực hiện chạy Job thủ công 
```sql
begin 
job_auto_calculate_salary;
end;
```
### Kiểm tra bảng job_logs kết quả chạy job
![](./images/Screenshot%202024-04-07%20234316.png)

Job ngày 04/04 đã được chạy xong với thời gian 4 phút 39 giây với số lượng 10000 nhân viên

### Kiểm tra lại số dư của nhân viên 111149
![](./images/Screenshot%202024-04-07%20234644.png)
Số dư khả dụng đã tăng lên thành 14,990,909

### Thực hiện rút số tiền 15,000,000 từ tài khoản của nhân viên 111149
![](./images/Screenshot%202024-04-07%20235505.png)

Hệ thống báo số dư khả dụng không đủ

### Thực hiện rút số tiền 14,000,000 từ tài khoản của nhân viên 111149
![](./images/Screenshot%202024-04-07%20235714.png)

### Kiểm tra lại số dư của nhân viên 111149
![](./images/Screenshot%202024-04-07%20235844.png)

Số dư khả dụng còn lại 990,909