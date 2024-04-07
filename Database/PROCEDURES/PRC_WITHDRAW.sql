--------------------------------------------------------
--  DDL for Procedure PRC_WITHDRAW
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "SALARYHERO"."PRC_WITHDRAW" (
p_userid IN  varchar2,
p_amount IN  varchar2,
p_err_code IN OUT varchar2,
p_err_param IN OUT varchar2)

AS
CURRDATE date;
l_count number;
l_count1 number;
v_month_salary month_salary%rowtype;
BEGIN

    p_err_code  := '0';
    p_err_param := 'SUCCESS';
    
    select to_date(config_value,'DD/MM/YYYY')
    into CURRDATE
    from config
    where config_key='CURRDATE';
    
    select count(1)
    into l_count 
    from employees
    where userid=p_userid ;
    
    if l_count=0 then 
        p_err_code:='-1';
        p_err_param:='User not found';
    else
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
    end if;
    commit;
    exception
    when others then
      p_err_code := '-1';
      p_err_param:='ERROR';
    end prc_withdraw;

/
