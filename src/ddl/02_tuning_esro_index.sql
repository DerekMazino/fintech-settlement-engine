CREATE INDEX idx_trx_riesgos_esro on transacciones_staging(
    estado_proc
,   categoria
,   fecha_trx
,   monto_compra
) TABLESPACE ts_fintech_idx;

-- Recolección inicial de estadísticas CBO
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