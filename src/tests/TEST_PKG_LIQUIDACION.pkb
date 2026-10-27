CREATE OR REPLACE PACKAGE BODY test_pkg_liquidacion AS
    
    PROCEDURE test_cashback_oro
    AS
        vl_resultado  NUMBER;
    BEGIN
        vl_resultado := PKG_LIQUIDACION_CORE.fn_get_cashback_pct( 100000
                                                                , 'ORO'
                                                                );

        ut.expect(vl_resultado).to_equal(5000);                                        
    END test_cashback_oro;

    
    PROCEDURE test_cashback_bronce
    AS
        vl_resultado NUMBER;
        vl_monto_compra CONSTANT NUMBER := 50000;
        vl_cashback_obtenido CONSTANT NUMBER := 500;
    BEGIN
        vl_resultado := PKG_LIQUIDACION_CORE.fn_get_cashback_pct( vl_monto_compra
                                                                , 'BRONCE'
                                                                );
        ut.expect(vl_resultado).to_equal(vl_cashback_obtenido);                                                                
    END test_cashback_bronce;

    
    PROCEDURE test_proceso_lote_diario 
    AS
        vl_cliente_id  CONSTANT NUMBER := 9999;
        vl_trx_id      CONSTANT NUMBER := 8888;
        vl_monto       CONSTANT NUMBER := 200000;
        vl_estado_post transacciones_staging.estado_proc%TYPE;
        vl_saldo_post  clientes_billetera.saldo_cashback%TYPE;
    BEGIN
        -- Preparar escenario
        INSERT INTO clientes_billetera (cliente_id, nombre, nivel, saldo_cashback, estado)
        VALUES (vl_cliente_id, 'Cliente Test QA', 'PLATA', 0, 'ACTIVO');

        INSERT INTO transacciones_staging (trx_id, cliente_id, monto_compra, fecha_trx, categoria, estado_proc)
        VALUES (vl_trx_id, vl_cliente_id, vl_monto, SYSDATE, 'RETAIL', 'PENDIENTE');

        -- Ejecutar procedimiento batch
        pkg_liquidacion_core.pr_procesar_lote_diario;

        -- Validar estado
        SELECT estado_proc 
        INTO vl_estado_post
        FROM transacciones_staging
        WHERE trx_id = vl_trx_id;

        -- Validar saldo (200k al 3% PLATA = 6,000)
        SELECT saldo_cashback 
        INTO vl_saldo_post
        FROM clientes_billetera
        WHERE cliente_id = vl_cliente_id;

        ut.expect(vl_estado_post).to_equal('LIQUIDADO');
        ut.expect(vl_saldo_post).to_equal(6000);
    END test_proceso_lote_diario;
END;
/