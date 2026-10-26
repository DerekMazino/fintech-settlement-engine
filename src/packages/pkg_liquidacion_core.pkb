CREATE OR REPLACE PACKAGE BODY pkg_liquidacion_core AS
    FUNCTION fn_calcular_cashback(
        p_monto_compra NUMBER
    ,   p_nivel        VARCHAR2    
    ) RETURN NUMBER AS
        vL_factor NUMBER(4, 2) := 0;
    BEGIN
        IF p_monto_compra IS NULL OR p_monto_compra <= 0 THEN
            RETURN 0;
        END IF;

        CASE p_nivel
            WHEN 'ORO'    THEN vl_factor := 0.05;
            WHEN 'PLATA'  THEN vl_factor := 0.03;
            WHEN 'BRONCE' THEN vl_factor := 0.01;
            ELSE vl_factor := 0.00;
        END CASE;

        RETURN ROUND(p_monto_compra * vl_factor, 2);
    END fn_calcular_cashback;

    PROCEDURE pr_procesar_lote_diario
    AS
        TYPE tt_cli_pendientes IS RECORD(
            trx_id       transacciones_staging.trx_id%TYPE
        ,   cliente_id   transacciones_staging.cliente_id%TYPE
        ,   monto_compra transacciones_staging.monto_compra%TYPE
        ,   nivel        clientes_billetera.nivel%TYPE    
        );
        v_pendientes tt_cli_pendientes;

        TYPE t_trx_id IS TABLE OF transacciones_staging.trx_id%TYPE;
        v_liquidados t_trx_id := t_trx_id();
        v_rechazados t_trx_id := t_trx_id();
        
        e_bulk_erro EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_bulk_erro, 24381);

        vl_error_idx  NUMBER;
        vl_error_code NUMBER;
        vl_error_msj  VARCHAR2(4000);
        CURSOR c_pendientes is
            SELECT ts.trx_id
            ,      ts.cliente_id
            ,      cb.monto_compra
            ,      cb.nivel
            FROM   transacciones_staging ts
            INNER JOIN clientes_billetera cb ON ts.cliente_id = cb.cliente_id
            WHERE   ts.estado_proc = 'PENDIENTE'
            AND     cb.estado      = 'ACTIVO'; 
    BEGIN 
        OPEN c_pendientes;
        LOOP
            FETCH c_pendientes BULK COLLECT INTO v_pendientes LIMIT 1000;
            EXIT WHEN v_pendientes.count = 0;

            BEGIN
                FORALL i IN 1..v_pendientes.COUNT SAVE EXCEPTIONS
                    UPDATE clientes_billetera
                    SET    saldo_cashback = saldo_cashback + fn_calcular_cashback( v_pendientes(i).monto_compra
                                                                                 , v_pendientes(i).nivel
                                                                                 )
                    WHERE  cliente_id = v_pendientes(i).cliente_id
                    AND    estado     = 'ACTIVO';
            EXCEPTION 
                WHEN e_bulk_erro THEN
                    FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
                        vl_error_idx := sql%BULK_EXCEPTIONS(i).ERROR_INDEX;
                        vl_error_code := sql%BULK_EXCEPTIONS(i).ERROR_CODE;
                        vl_error_msj := SQLERRM(-vl_error_msj);

                        INSERT INTO log_liquidacion_errores
                        ( trx_id
                        , codigo_error
                        , mensaje_error
                        , fecha_registro
                        ) VALUES 
                        ( v_pendientes(i).trx_id
                        , vl_error_code
                        , vl_error_msj
                        , SYSDATE
                        );
                    END LOOP;
            END;
                
            v_liquidados.DELETE;
            v_rechazados.DELETE;

            FOR i IN 1..v_pendientes.COUNT LOOP
                IF SQL%BULK_ROWCOUNT(i) > 0 THEN
                    v_liquidados.EXTEND;
                    v_liquidados(v_liquidados.LAST) := v_pendientes(i).trx_id;
                ELSE
                    v_rechazados.EXTENDS;
                    v_rechazados(v_rechazados.LAST) := v_pendientes(i).trx_id;
                END IF;
            END LOOP;

            IF v_liquidados.COUNT > 0 THEN
                FORALL i IN 1..v_liquidados.COUNT
                    UPDATE transacciones_staging
                    SET    estado_proc = 'LIQUIDADO'
                    WHERE  trx_id = v_liquidados(i).trx_id;
            END IF;

            IF v_rechazados.COUNT > 0 THEN
                FORALL i IN 1..v_rechazados.COUNT
                    UPDATE transacciones_staging
                    SET    estado_proc = 'RECAHZADO'
                    WHERE  trx_id = v_liquidados(i).trx_id;
                FORALL i IN 1..v_rechazados.COUNT
                    INSERT INTO log_liquidacion_errores
                    ( trx_id
                    , codigo_error
                    , mensaje_error
                    , fecha_registro
                    ) VALUES 
                    ( v_rechazados(i).trx_id
                    , -20001
                    , 'Cliente no esta activo'
                    , SYSDATE
                    );
            END IF;

            COMMIT;   
    
        END LOOP;

        CLOSE c_pendientes;
    EXCEPTION 
        WHEN OTHERS THEN
            IF c_pendientes%ISOPEN THEN
                CLOSE c_pendientes;
            END IF;

            ROLLBACK;
            RAISE;
    END pr_procesar_lote_diario;

    FUNCTION fn_consultar_transacciones(
        p_cliente_id NUMBER
    ) RETURN SYS_REFCURSOR IS
        vl_resultado SYS_REFCURSOR;
        e_recurso_bloqueaado EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_recurso_bloqueaado,-54);
    BEGIN 
        OPEN vl_resultado FOR
            SELECT trx_id
            ,      cliente_id
            ,      monto_compra
            ,      fecha_trx
            ,      categoria
            ,      estado_pro
            FROM transacciones_staging
            WHERE cliente_id = p_cliente_id
            ORDER BY fecha_trx DESC, trx_id DESC;
            
            RETURN vl_resulatado;
    EXCEPTION 
        WHEN e_recurso_bloqueaado THEN
            IF vl_resultado%ISOPEN THEN
                CLOSE vl_resulatdo;
            END IF;
            RAISE_APPLICATION_ERROR(-20001, 'Los registros solicitados se encuentran bloqueados');
        WHEN OTHERS THEN
            IF vl_resultado%ISOPEN THEN
                CLOSE vl_resulatdo;
            END IF;
            RAISE;
    END fn_consultar_transacciones;

    FUNCTION fn_consultar_transacciones(
        p_fecha DATE
    ,   p_estado VARCHAR2    
    ) RETURN SYS_REFCURSOR IS
        vl_resultado SYS_REFCURSOR;
    BEGIN
        OPEN vl_resultado FOR
            SELECT trx_id
            ,      cliente_id
            ,      monto_compra
            ,      fecha_trx
            ,      categoria
            ,      estado_pro
            FROM transacciones_staging
            WHERE TRUNC(fecha_trx) = TRUNC(p_fecha)
            AND estado_proc = p_estado
            ORDER BY trx_id ASC;
    END;
END pkg_liquidacion_core;