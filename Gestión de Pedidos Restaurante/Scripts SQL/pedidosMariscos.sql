
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE pedidos CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_pedidos';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    -- Elimina la tabla de bitácora
    EXECUTE IMMEDIATE 'DROP TABLE pedidos_bit CASCADE CONSTRAINTS ';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignora errores
END;
/


-- =============================================
-- TABLA PEDIDOS
-- =============================================

CREATE TABLE pedidos (
    id_pedido NUMBER PRIMARY KEY,
    id_cliente NUMBER,
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total NUMBER(10,2),
    estado_pedido VARCHAR2(50),
    fecha_cancelacion TIMESTAMP,
    estado NUMBER DEFAULT 1,

    CONSTRAINT fk_pedido_cliente
    FOREIGN KEY(id_cliente)
    REFERENCES cliente(id_cliente)
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE pedidos IS 'Tabla que almacena los pedidos realizados por los clientes';
COMMENT ON COLUMN pedidos.id_pedido IS 'Identificador unico del pedido (llave primaria)';
COMMENT ON COLUMN pedidos.id_cliente IS 'Identificador del cliente que realiza el pedido (llave foranea a clientes)';
COMMENT ON COLUMN pedidos.fecha_pedido IS 'Fecha y hora en que se realizo el pedido';
COMMENT ON COLUMN pedidos.total IS 'Monto total del pedido';
COMMENT ON COLUMN pedidos.estado_pedido IS 'Estado actual del pedido (ej: pendiente, pagado, cancelado)';
COMMENT ON COLUMN pedidos.fecha_cancelacion IS 'Fecha en que se cancelo el pedido (si aplica)';
COMMENT ON COLUMN pedidos.estado IS 'Estado del registro (1=Activo, 0=Inactivo)';

-- =============================================
-- SECUENCIAS
-- =============================================
CREATE SEQUENCE seq_pedidos START WITH 1 INCREMENT BY 1;

-- Tabla de bitácora de pedidos
CREATE TABLE pedidos_bit (
    id_pedido_bit NUMBER PRIMARY KEY,   -- ID único de la bitácora
    id_pedido NUMBER NOT NULL,          -- ID del pedido original
    id_cliente NUMBER,

    fecha_pedido TIMESTAMP,
    total NUMBER(10,2),
    estado_pedido VARCHAR2(50),
    fecha_cancelacion TIMESTAMP,
    estado NUMBER DEFAULT 1,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- registro del movimiento
    fecha_modificacion TIMESTAMP,                       -- actualización del registro
    accion VARCHAR2(10) NOT NULL,                       -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                            -- origen de la operación
);

-- Documentación de la tabla de bitácora
COMMENT ON TABLE pedidos_bit IS 'Tabla de bitacora que registra los movimientos realizados sobre los pedidos';
COMMENT ON COLUMN pedidos_bit.id_pedido_bit IS 'Identificador único de la bitácora';
COMMENT ON COLUMN pedidos_bit.id_pedido IS 'ID del pedido ';
COMMENT ON COLUMN pedidos_bit.id_cliente IS 'ID del cliente asociado al pedido';
COMMENT ON COLUMN pedidos_bit.fecha_pedido IS 'Fecha en la que se realizó el pedido ';
COMMENT ON COLUMN pedidos_bit.total IS 'Total del pedido ';
COMMENT ON COLUMN pedidos_bit.estado_pedido IS 'Estado del pedido (pendiente, pagado, cancelado, etc.)';
COMMENT ON COLUMN pedidos_bit.fecha_cancelacion IS 'Fecha de cancelación del pedido si aplica';
COMMENT ON COLUMN pedidos_bit.estado IS 'Estado del registro (activo/inactivo)';
COMMENT ON COLUMN pedidos_bit.fecha_creacion IS 'Fecha en la que se registró el movimiento en la bitácora';
COMMENT ON COLUMN pedidos_bit.fecha_modificacion IS 'Fecha en la que se modificó el registro en la bitácora';
COMMENT ON COLUMN pedidos_bit.accion IS 'Tipo de operación realizada: INSERT, UPDATE o DELETE';
COMMENT ON COLUMN pedidos_bit.ip IS 'Dirección IP desde donde se realizó la operación';

-- Registra en bitácora las inserciones y modificaciones de pedidos
CREATE OR REPLACE TRIGGER TRG_PEDIDOS_AUD
AFTER INSERT OR UPDATE ON PEDIDOS
FOR EACH ROW
DECLARE
    -- Tipo de operación realizada
    V_ACCION VARCHAR2(20);

    -- ID de la bitácora
    V_ID_BIT NUMBER;

    -- Fecha de creación registrada en bitácora
    V_FECHA_CREACION TIMESTAMP := NULL;

    -- Fecha de modificación registrada en bitácora
    V_FECHA_MODIFICACION TIMESTAMP := NULL;

BEGIN
    -- Generar ID de bitácora (sin secuencia)
    SELECT NVL(MAX(ID_PEDIDO_BIT), 0) + 1
    INTO V_ID_BIT
    FROM PEDIDOS_BIT;

    -- Registro creado
    IF INSERTING THEN
        V_ACCION := 'INSERT';
        V_FECHA_CREACION := SYSTIMESTAMP;

    -- Registro modificado
    ELSIF UPDATING THEN
        V_FECHA_MODIFICACION := SYSTIMESTAMP;
        V_FECHA_CREACION := SYSTIMESTAMP;

        -- Cambio de estado
        IF :OLD.ESTADO = 1 AND :NEW.ESTADO = 0 THEN
            V_ACCION := 'INACTIVE';

        ELSIF :OLD.ESTADO = 0 AND :NEW.ESTADO = 1 THEN
            V_ACCION := 'ACTIVE';

        -- Cancelación de pedido
        ELSIF :OLD.ESTADO_PEDIDO <> :NEW.ESTADO_PEDIDO
              AND :NEW.ESTADO_PEDIDO = 'CANCELADO' THEN
            V_ACCION := 'CANCEL';

        -- Actualización general
        ELSE
            V_ACCION := 'UPDATE';
        END IF;
    END IF;

    -- Inserta el movimiento en la bitácora
    INSERT INTO PEDIDOS_BIT (
        ID_PEDIDO_BIT,
        ID_PEDIDO,
        ID_CLIENTE,
        FECHA_PEDIDO,
        TOTAL,
        ESTADO_PEDIDO,
        FECHA_CANCELACION,
        ESTADO,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES (
        V_ID_BIT,
        :NEW.ID_PEDIDO,
        :NEW.ID_CLIENTE,
        :NEW.FECHA_PEDIDO,
        :NEW.TOTAL,
        :NEW.ESTADO_PEDIDO,
        :NEW.FECHA_CANCELACION,
        :NEW.ESTADO,
        V_FECHA_CREACION,
        V_FECHA_MODIFICACION,
        V_ACCION,
        SYS_CONTEXT('USERENV', 'IP_ADDRESS')
    );
END;
/

-- Obtiene la IP o nombre del host de la conexión
CREATE OR REPLACE FUNCTION FN_GET_IP
RETURN VARCHAR2
IS
BEGIN
    -- Obtiene IP o host de la sesión actual
    RETURN NVL(
        SYS_CONTEXT('USERENV','IP_ADDRESS'),
        SYS_CONTEXT('USERENV','HOST')
    );

EXCEPTION
    -- Retorna valor por defecto si ocurre un error
    WHEN OTHERS THEN
        RETURN 'LOCALHOST';
END FN_GET_IP;
/