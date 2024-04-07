--------------------------------------------------------
--  DDL for Procedure PRC_GET_EMPLOYEES
--------------------------------------------------------
set define off;

  CREATE OR REPLACE NONEDITIONABLE PROCEDURE "SALARYHERO"."PRC_GET_EMPLOYEES" (p_REFCURSOR IN OUT SYS_REFCURSOR ,
p_userid IN  varchar2,
p_err_code IN OUT varchar2,
p_err_param IN OUT varchar2)

AS
BEGIN

    p_err_code  := '0';
    p_err_param := 'SUCCESS';

     OPEN p_refcursor FOR
        select userid "userID",
            fullname "fullname",
            userType "userType"
        from employees
        where userid=p_userid
        or p_userid='ALL'
        order by  userid ;
    exception
    when others then
      p_err_code := '-1';
      p_err_param:='ERROR';
    end prc_get_employees;

/
