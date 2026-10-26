CREATE OR REPLACE PACKAGE pkg_liquidacion_core AS
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