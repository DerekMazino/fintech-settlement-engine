CREATE OR REPLACE PACKAGE test_pkg_liquidacion AS
    --%suite(Suite de pruebas liquidación y cashback)
    --%rollback(auto)

    --%test(Verificar que cliente ORO con compra de 100,000 recibe 5,000 de cashback)
    PROCEDURE test_cashback_oro;

    --%test(Verificar que cliente BRONCE con compra de 50,000 recibe 500 de cashback)
    PROCEDURE test_cashback_bronce;

    --%test(Procesamiento de lote diario liquida transacciones pendientes y actualiza saldo)
    PROCEDURE test_proceso_lote_diario;
END;
/