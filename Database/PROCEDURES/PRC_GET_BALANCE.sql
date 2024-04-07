-- Start of DDL Script for Procedure SALARYHERO.PRC_GET_BALANCE
-- Generated 07-Apr-2024 23:33:22 from SALARYHERO@(DESCRIPTION =(ADDRESS_LIST =(ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521)))(CONNECT_DATA =(SERVICE_NAME = ORCLPDB1)))

CREATE OR REPLACE 
PROCEDURE prc_get_balance(p_REFCURSOR IN OUT SYS_REFCURSOR ,
p_userid IN  varchar2,
p_err_code IN OUT varchar2,
p_err_param IN OUT varchar2)

AS
CURRDATE date;
BEGIN

    p_err_code  := '0';
    p_err_param := 'SUCCESS';

    select to_date(config_value,'DD/MM/YYYY')
    into CURRDATE
    from config
    where config_key='CURRDATE';

    OPEN p_refcursor FOR
        select
            round(balance,0) "balance",
            round(avail_balance,0) "availableBalance",
            month_salary.userid "userID",
            to_char(CURRDATE,'DD/MM/YYYY') currentDate
        from month_salary
        join employees on month_salary.userid=employees.userid
        where month_salary.userid=p_userid
        and calc_month=to_number(to_char(CURRDATE,'MM'))
        and calc_year=to_number(to_char(CURRDATE,'YYYY'));
    exception
    when others then
      p_err_code := '-1';
      p_err_param:='ERROR';
    end prc_get_balance;
/



-- End of DDL Script for Procedure SALARYHERO.PRC_GET_BALANCE

