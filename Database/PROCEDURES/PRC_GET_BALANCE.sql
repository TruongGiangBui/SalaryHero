--------------------------------------------------------
--  DDL for Procedure PRC_GET_BALANCE
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "SALARYHERO"."PRC_GET_BALANCE" (p_REFCURSOR IN OUT SYS_REFCURSOR ,
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
            balance "balance",
            avail_balance "availableBalance",
            month_salary.userid "userID" 
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
