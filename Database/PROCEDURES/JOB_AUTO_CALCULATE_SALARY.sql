--------------------------------------------------------
--  DDL for Procedure JOB_AUTO_CALCULATE_SALARY
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "SALARYHERO"."JOB_AUTO_CALCULATE_SALARY" 
IS
   PROCESSING varchar2(10);
   v_id number;
   CURRDATE date;
   MAXPROCESS number;
   v_salary number;
   v_count number;
   v_num_of_workday number;
   v_date date;
BEGIN

   -- Lấy thông tin ngày hiện tại
   select to_date(config_value,'DD/MM/YYYY')
   into CURRDATE
   from config
   where config_key='CURRDATE';

   -- Số bản ghi xử lý tối đa 1 lần
   select to_number(config_value)
   into MAXPROCESS
   from config
   where config_key='MAXPROCESS';


   select seq_job_logs.NEXTVAL
   into v_id
   from dual;

   -- Insert thông tin log cho quá trình chạy JOB
   insert into job_logs(
        autoid,
        jobname,
        execute_date,
        start_time,
        end_time,
        log_msg
   )values(
        v_id,
        'job_auto_calculate_salary',
        CURRDATE,
        CURRENT_TIMESTAMP,
        null,
        'MAXPROCESS '||MAXPROCESS
   );

   -- Cập nhật trạng thái đang chạy JOB để trong quá trình tính toán nhân viên không được thực hiện các thao tác rút tiền
   update config
   set config_value='Y'
   where config_key='PROCESSING'
   and config_value='N';

   commit;



   -- Nếu là đầu tháng mới thì tính số ngày làm việc trong tháng
   if to_char(CURRDATE,'DD')='01' then
       v_num_of_workday:=0;
       v_date:=CURRDATE;
       loop
            if MOD(TO_CHAR(v_date, 'J'), 7) + 1 not IN (6, 7) then
                v_num_of_workday:=v_num_of_workday+1;
            end if;
            v_date:=v_date+1;
            if to_char(v_date,'MM')<>to_char(CURRDATE,'MM') then
                update config
                set config_value=to_char(v_num_of_workday)
                where config_key='NUMOFWORKDAY';
                exit;
            end if;
       end loop;
   else
       select to_number(config_value)
       into v_num_of_workday
       from config
       where config_key='NUMOFWORKDAY';
   end if;






   loop
       select config_value
       into PROCESSING
       from config
       where config_key='PROCESSING';

       if PROCESSING='Y' then

           --Lấy ra danh sách MAXPROCESS employee chưa tính lương ngày hôm nay
           for employee in (
                select * from (
                    select employees.*, salary.base_salary, timesheet.attendant
                    from employees
                    join timesheet on employees.userid=timesheet.userid
                    join salary on salary.userid=employees.userid
                    where timesheet.calculated='N'
                    and salary.from_date<=CURRDATE
                    and salary.exp_date>=CURRDATE
                    and timesheet.ts_date=CURRDATE
                    order by employees.userid
                ) where ROWNUM <= MAXPROCESS
           )loop
                select count(1)
                into v_count
                from month_salary
                where userid=employee.userid
                and calc_month=to_number(to_char(CURRDATE,'MM'))
                and calc_year=to_number(to_char(CURRDATE,'YYYY'));

                if v_count=0 then
                    insert into month_salary(
                        userid,
                        balance,
                        avail_balance,
                        calc_month,
                        calc_year
                    )values(
                        employee.userid,
                        0,
                        0,
                        to_number(to_char(CURRDATE,'MM')),
                        to_number(to_char(CURRDATE,'YYYY'))
                    );
                end if;

                if employee.attendant='Y' then
                    --Tính phần lương cộng thêm cho 2 kiểu nhân viên
                    if employee.USERTYPE='D' then
                        v_salary:=employee.base_salary;
                    else
                        v_salary:=employee.base_salary/v_num_of_workday;
                    end if;

                    -- Cập nhật lương cho nhân viên
                    update month_salary
                    set balance=balance+v_salary,
                    avail_balance=balance+v_salary
                    where userid=employee.userid
                    and calc_month=to_number(to_char(CURRDATE,'MM'))
                    and calc_year=to_number(to_char(CURRDATE,'YYYY'));
                end if;

                -- Cập nhật trạng thái đã tính toán cho timesheet
                update timesheet
                set calculated='Y'
                where userid=employee.userid
                and timesheet.ts_date=CURRDATE;
           end loop;


           select count(1)
           into v_count
           from employees
           join timesheet on employees.userid=timesheet.userid
           where timesheet.calculated='N'
           and timesheet.ts_date=CURRDATE;

           --Nếu đã xử lý xong hết thì chạy qua ngày mới
           if v_count=0 then
                update config
                set config_value=to_char(CURRDATE+1,'DD/MM/YYYY')
                where config_key='CURRDATE';

                exit;
           end if;
           commit;
       end if;
   end loop;

   -- Cập nhật thời gian kết thúc JOB
   update job_logs
   set end_time =CURRENT_TIMESTAMP
   where autoid=v_id;

   update config
   set config_value='N'
   where config_key='PROCESSING';

   commit;
EXCEPTION
WHEN OTHERS
   THEN
      ROLLBACK;
      update job_logs
      set log_msg=log_msg||' Error:'||dbms_utility.format_error_backtrace,
      end_time =CURRENT_TIMESTAMP
      where autoid=v_id;

      update config
      set config_value='N'
      where config_key='PROCESSING';
      commit;
END;

/
