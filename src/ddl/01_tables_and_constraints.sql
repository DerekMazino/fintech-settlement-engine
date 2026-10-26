CREATE TABLE clientes_billetera(
    cliente_id     NUMBER
,   nombre         VARCHAR2(100)
,   nivel          VARCHAR2(10)
,   saldo_cashback NUMBER(12,2) DEFAULT 0 
,   estado         VARCHAR2(10) DEFAULT 'ACTIVO'
,   CONSTRAINT pk_clientes_billetera PRIMARY KEY(cliente_id)
        USING INDEX TABLESPACE ts_fintech_idx
,   CONSTRAINT ck_cliente_nivel CHECK (nivel IN ('BRONCE', 'PLATA', 'ORO'))
,   CONSTRAINT ck_cliente_estado CHECK (estado IN ('ACTIVO','BLOQUEADO'))
) TABLESPACE ts_fintech_data;

CREATE TABLE transacciones_staging(
    trx_id       NUMBER
,   cliente_id   NUMBER NOT NULL
,   monto_compra NUMBER(12,2)
,   fecha_trx    DATE
,   categoria    VARCHAR2(20)
,   estado_proc  VARCHAR(15) DEFAULT 'PENDIENTE'
,   CONSTRAINT pk_transacciones_staging PRIMARY KEY (trx_id)
        USING INDEX TABLESPACE ts_fintech_idx
,   CONSTRAINT fk_trx_cliente FOREIGN KEY (cliente_id) 
        REFERENCES clientes_billetera(cliente_id)
,   CONSTRAINT ch_trans_estado_p CHECK (estado_proc IN ('PENDIENTE','LIQUIDADO','RECHAZADO'))
) TABLESPACE ts_fintech_data;

CREATE TABLE log_liquidacion_errores (
    log_id           NUMBER GENERATED ALWAYS AS IDENTITY,
    trx_id           NUMBER,
    codigo_error     NUMBER NOT NULL,
    mensaje_error    VARCHAR2(4000) NOT NULL,
    fecha_registro   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_log_liquidacion PRIMARY KEY (log_id)
        USING INDEX TABLESPACE TS_FINTECH_IDX
) TABLESPACE TS_FINTECH_DATA;