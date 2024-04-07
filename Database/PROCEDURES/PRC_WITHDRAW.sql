-- Start of DDL Script for Procedure SALARYHERO.PRC_WITHDRAW
-- Generated 07-Apr-2024 21:32:15 from SALARYHERO@(DESCRIPTION =(ADDRESS_LIST =(ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521)))(CONNECT_DATA =(SERVICE_NAME = ORCLPDB1)))

CREATE OR REPLACE 
PROCEDURE prc_withdraw(
p_userid IN  varchar2,
p_amount IN  varchar2,
p_err_code IN OUT varchar2,
p_err_param IN OUT varchar2)

AS
CURRDATE date;
l_count number;
l_count1 number;
v_month_salary month_salary%rowtype;
PROCESSING varchar2(10);
BEGIN

    p_err_code  := '0';
    p_err_param := 'SUCCESS';

    select config_value
    into PROCESSING
    from config
    where config_key='PROCESSING';

    select to_date(config_value,'DD/MM/YYYY')
    into CURRDATE
    from config
    where config_key='CURRDATE';

    select count(1)
    into l_count
    from employees
    where userid=p_userid ;

    if PROCESSING='Y' then
        p_err_code:='-1';
        p_err_param:='The system is calculating, please try again later';
        return;
    end if;

    if l_count=0 then
        p_err_code:='-1';
        p_err_param:='User not found';
        return;
    end if;

    select count (1)
    into l_count1
    from month_salary
    join employees on month_salary.userid=employees.userid
    where month_salary.userid=p_userid
    and calc_month=to_number(to_char(CURRDATE,'MM'))
    and calc_year=to_number(to_char(CURRDATE,'YYYY'));

    if l_count1=0 then
        p_err_code:='-1';
        p_err_param:='Not enough balance';
    else
        select month_salary.*
        into v_month_salary
        from month_salary
        join employees on month_salary.userid=employees.userid
        where month_salary.userid=p_userid
        and calc_month=to_number(to_char(CURRDATE,'MM'))
        and calc_year=to_number(to_char(CURRDATE,'YYYY'));

        if v_month_salary.avail_balance<to_number(p_amount) then
            p_err_code:='-1';
            p_err_param:='Not enough balance';
        else
            update month_salary
            set balance=balance-to_number(p_amount),
            avail_balance=avail_balance-to_number(p_amount)
            where month_salary.userid=p_userid
            and calc_month=to_number(to_char(CURRDATE,'MM'))
            and calc_year=to_number(to_char(CURRDATE,'YYYY'));
        end if;

    end if;
    commit;
    exception
    when others then
      p_err_code := '-1';
      p_err_param:='ERROR';
    end prc_withdraw;
/



-- End of DDL Script for Procedure SALARYHERO.PRC_WITHDRAW

