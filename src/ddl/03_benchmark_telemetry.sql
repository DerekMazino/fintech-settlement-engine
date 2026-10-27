ALTER SESSION SET CURRENT_SCHEMA = FINTECH_USER;
SET TIMING ON;

-- 1. Sembrado masivo
INSERT /*+ APPEND */ INTO clientes_billetera (cliente_id, nombre, nivel, saldo_cashback, estado)
SELECT LEVEL, 'Cliente ' || LEVEL,
       CASE MOD(LEVEL, 3) WHEN 0 THEN 'ORO' WHEN 1 THEN 'PLATA' ELSE 'BRONCE' END,
       0, 'ACTIVO'
  FROM dual CONNECT BY LEVEL <= 5000;
COMMIT;

INSERT /*+ APPEND */ INTO transacciones_staging (trx_id, cliente_id, monto_compra, fecha_trx, categoria, estado_proc)
SELECT LEVEL,
       TRUNC(DBMS_RANDOM.VALUE(1, 5001)),
       ROUND(DBMS_RANDOM.VALUE(10000, 500000), 2),
       DATE '2026-10-01' + DBMS_RANDOM.VALUE(0, 30),
       CASE MOD(LEVEL, 4) WHEN 0 THEN 'RETAIL' WHEN 1 THEN 'VIAJES' WHEN 2 THEN 'RESTAURANTES' ELSE 'SERVICIOS' END,
       'LIQUIDADO'
  FROM dual CONNECT BY LEVEL <= 100000;
COMMIT;

-- 2. Recolección de estadísticas CBO
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname          => 'FINTECH_USER',
        tabname          => 'TRANSACCIONES_STAGING',
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt       => 'FOR ALL COLUMNS SIZE AUTO',
        cascade          => TRUE,
        no_invalidate    => FALSE
    );
END;
/

-- 3. Telemetría de ejecución: Consulta analítica de riesgos
ALTER SESSION SET STATISTICS_LEVEL = ALL;

SELECT categoria,
       COUNT(*) AS total_operaciones,
       SUM(monto_compra) AS volumen_total
  FROM transacciones_staging
 WHERE estado_proc = 'LIQUIDADO'
   AND fecha_trx >= TO_DATE('2026-10-01', 'YYYY-MM-DD')
   AND fecha_trx < TO_DATE('2026-11-01', 'YYYY-MM-DD')
 GROUP BY categoria;

SET LINESIZE 200 PAGESIZE 100;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(null, null, 'ALLSTATS LAST'));

EXIT;
