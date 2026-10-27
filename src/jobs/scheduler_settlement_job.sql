ALTER SESSION SET CURRENT_SCHEMA = FINTECH_USER;

SET SERVEROUTPUT ON;

DECLARE
    vl_job_existe NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   vl_job_existe
    FROM USER_SCHEDULER_JOBS
    WHERE JOB_NAME = 'JOB_LIQUIDACION_NOCTURNA';

    IF vl_job_existe > 0 THEN
        DBMS_SCHEDULER.DROP_JOB(
            job_name => 'JOB_LIQUIDACION_NOCTURNA'
        ,   force => TRUE   
        );
    END IF;

    DBMS_SCHEDULER.CREATE_JOB(
        JOB_NAME => 'JOB_LIQUIDACION_NOCTURNA'
    ,   JOB_TYPE => 'STORED_PROCEDURE'
    ,   JOB_ACTION => 'PKG_LIQUIDACION_CORE.PR_PROCESAR_LOTE_DIARIO'
    ,   NUMBER_OF_ARGUMENTS => 0
    ,   START_DATE => SYSTIMESTAMP
    ,   REPEAT_INTERVAL => 'FREQ=WEEKLY; BYDAY=MON,TUE,WED,THU,FRI,SAT; BYHOUR=23; BYMINUTE=0; BYSECOND=0'
    ,   ENABLED => FALSE
    ,   COMMENTS => 'Procesamiento diario'
    );

    DBMS_SCHEDULER.ENABLE(
        NAME => 'JOB_LIQUIDACION_NOCTURNA'
    );
END;
/

SELECT job_name,                                -- Nombre del job ejecutado
       status,                                  -- Estado final ('SUCCEEDED', 'FAILED', 'STOPPED', etc.)
       actual_start_date,                       -- Timestamp exacto en el que comenzó a correr
       run_duration,                            -- Intervalo de tiempo transcurrido (diferencia fin vs inicio)
       error#,                                  -- Código numérico de error Oracle (0 si fue exitoso)
       -- Se trunca o muestra el mensaje completo capturado por el motor ante una falla
       SUBSTR(additional_info, 1, 300) AS detalle_error
  FROM user_scheduler_job_run_details
 WHERE job_name = 'JOB_LIQUIDACION_NOCTURNA'         -- Filtramos las ejecuciones de este job
 ORDER BY actual_start_date DESC;

EXIT;