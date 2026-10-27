CREATE OR REPLACE PACKAGE pkg_liquidacion_core AS
    -- Función pública para evaluación y testing unitario del cálculo de cashback
    FUNCTION fn_get_cashback_pct(
        p_monto_compra IN NUMBER
    ,   p_nivel        IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE pr_procesar_lote_diario;

    FUNCTION fn_consultar_transacciones(
        p_cliente_id NUMBER
    ) RETURN SYS_REFCURSOR;

    FUNCTION fn_consultar_transacciones(
        p_fecha DATE
    ,   p_estado VARCHAR2    
    ) RETURN SYS_REFCURSOR;
END;
/