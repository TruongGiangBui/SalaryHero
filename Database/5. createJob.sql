BEGIN
    DBMS_SCHEDULER.create_job (
    job_name => 'AUTO_CALCULATE_SALARY',
    job_type => 'PLSQL_BLOCK',
    job_action => 'BEGIN job_auto_calculate_salary;END;',
    start_date => CURRENT_TIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=0',
    enabled => TRUE);
END;