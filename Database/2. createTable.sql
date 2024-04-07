create sequence seq_employees;
create table employees(
    userid number default seq_employees.nextval,
    fullname varchar2(100),
    usertype varchar2(1),--(M,D)
    CONSTRAINT employees_pk PRIMARY KEY (userid)
);

create sequence seq_salary;
create table salary(
    autoid number default seq_salary.nextval,
    userid number,
    base_salary number,
    from_date date,
    exp_date date,
    CONSTRAINT salary_pk PRIMARY KEY (autoid),
    CONSTRAINT employees_fk
    FOREIGN KEY (userid)
    REFERENCES employees (userid)
);

create sequence seq_timesheet;
create table timesheet(
    autoid number default seq_timesheet.nextval,
    userid number,
    ts_date date,
    attendant varchar2(1),
    calculated varchar2(1) default 'N',
    CONSTRAINT timesheet_pk PRIMARY KEY (autoid),
    CONSTRAINT timesheet_fk
    FOREIGN KEY (userid)
    REFERENCES employees (userid)
);

create sequence seq_month_salary;
create table month_salary(
    autoid number default seq_month_salary.nextval,
    userid number,
    balance number,
    avail_balance number,
    calc_month number,
    calc_year number,
    CONSTRAINT month_salary_pk PRIMARY KEY (autoid),
    CONSTRAINT month_salary_fk
    FOREIGN KEY (userid)
    REFERENCES employees (userid)
);

create sequence seq_job_logs;
create table job_logs(
    autoid number,
    jobname varchar2(30),
    execute_date date,
    start_time timestamp,
    end_time timestamp,
    log_msg varchar2(1000)
);


create table config(
    config_key varchar2(100),
    config_value varchar2(100)
);
