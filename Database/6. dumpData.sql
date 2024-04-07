
truncate table timesheet; 
truncate table salary;  
truncate table month_salary;
truncate table employees;
truncate table job_logs;
begin 
    execute immediate 'alter sequence seq_timesheet increment by 1 minvalue 0';
    execute immediate 'alter sequence seq_salary increment by 1 minvalue 0';
    execute immediate 'alter sequence seq_month_salary increment by 1 minvalue 0';
    execute immediate 'alter sequence seq_employees increment by 1 minvalue 0';
end;

declare
    v_id number;
    v_count number:=0;
    v_records number:=10000;
begin
    

    loop
        select seq_employees.nextval
        into v_id from dual;
        
        insert into employees(
            userid,
            fullname,
            usertype
        )values(
            v_id,
            'Nhân viên số '||v_id,
            case when REMAINDER(round(dbms_random.value(0,1)*10,0), 2)=1 then 'D' else 'M' end
        );
        v_count:=v_count+1;
        if v_count=v_records then 
            exit;
        end if;
    end loop;
    commit;
end;

begin
    
    for employee in (select * from employees order by userid)
    loop
        
        insert into salary(
            userid,
            base_salary,
            from_date,
            exp_date
        )values(
            employee.userid,
            case when employee.usertype='M' then round(dbms_random.value(0,1)*100,0)*1000000 else round(dbms_random.value(0,1)*100,0)*100000 end,
            to_date('01/01/2024','DD/MM/YYYY'),
            to_date('01/01/2027','DD/MM/YYYY')
        );
    end loop;
    
    commit;
end;




declare
v_day number :=1;
v_date date;
begin
    
    for employee in (select * from employees order by userid)
    loop
        v_day:=1;
        loop
            if v_day>30 then 
                exit;
            end if;
            
            v_date:=to_date(lpad(v_day,2,'0')||'/04/2024','DD/MM/YYYY');
            
            if MOD(TO_CHAR(v_date, 'J'), 7) + 1 not IN (6, 7) then 
                insert into timesheet(
                    userid,
                    ts_date,
                    attendant
                )values(
                    employee.userid,
                    v_date,
                    case when round(dbms_random.value(0,1)*10,0)=1 then 'N' else 'Y' end
                );
            end if;
            v_day:=v_day+1;
        end loop;
    end loop;
    commit;
end;


update config
set config_value='01/04/2024'
where config_key='CURRDATE';
commit;

