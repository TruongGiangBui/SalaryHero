## Salary Project

## Mục lục

[1. Thiết kế cơ sở dữ liệu](#1-thiết-kế-cơ-sở-dữ-liệu)
[2. Thiết kế cơ sở dữ liệu](#1-thiết-kế-cơ-sở-dữ-liệu)


### 1. Thiết kế cơ sở dữ liệu
![](./images/Screenshot%202024-04-07%20132028.png)

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
    - *AVAIL_BALANCE:* Số tiền lương khả dụng có thể rút
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



