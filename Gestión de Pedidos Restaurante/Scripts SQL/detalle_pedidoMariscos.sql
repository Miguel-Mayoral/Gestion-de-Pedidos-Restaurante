
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE detalle_pedido CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_DETALLE_PEDIDO_BIT';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    -- Elimina la tabla de bitácora
    EXECUTE IMMEDIATE 'DROP TABLE detalle_pedido_bit CASCADE CONSTRAINTS ';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignora errores
END;
/

-- =============================================
-- TABLA DETALLE PEDIDO
-- =============================================

CREATE TABLE detalle_pedido (
    id_detalle NUMBER PRIMARY KEY,
    id_pedido NUMBER,
    id_producto NUMBER,
    cantidad NUMBER,
    precio_unitario NUMBER(10,2),
    subtotal NUMBER(10,2),
    estado NUMBER DEFAULT 1,

    CONSTRAINT fk_detalle_pedido
    FOREIGN KEY(id_pedido)
    REFERENCES pedidos(id_pedido),

    CONSTRAINT fk_detalle_producto
    FOREIGN KEY(id_producto)
    REFERENCES productos(id_producto)
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE detalle_pedido IS 'Tabla que almacena el detalle de los pedidos (productos incluidos en cada pedido)';
COMMENT ON COLUMN detalle_pedido.id_detalle IS 'Identificador unico del detalle del pedido (llave primaria)';
COMMENT ON COLUMN detalle_pedido.id_pedido IS 'Identificador del pedido (llave foranea a pedidos)';
COMMENT ON COLUMN detalle_pedido.id_producto IS 'Identificador del producto (llave foranea a productos)';
COMMENT ON COLUMN detalle_pedido.cantidad IS 'Cantidad de productos en el detalle del pedido';
COMMENT ON COLUMN detalle_pedido.precio_unitario IS 'Precio unitario del producto en el momento del pedido';
COMMENT ON COLUMN detalle_pedido.subtotal IS 'Subtotal calculado (cantidad * precio_unitario)';
COMMENT ON COLUMN detalle_pedido.estado IS 'Estado del registro (1=Activo, 0=Inactivo)';

-- =============================================
-- SECUENCIAS
-- =============================================
CREATE SEQUENCE SEQ_DETALLE_PEDIDO_BIT START WITH 1 INCREMENT BY 1;

-- Tabla de bitácora de detalle_pedido
CREATE TABLE detalle_pedido_bit (
    id_detalle_bit NUMBER PRIMARY KEY,  -- ID único de la bitácora
    id_detalle NUMBER NOT NULL,         -- ID del detalle original

    id_pedido NUMBER,
    id_producto NUMBER,
    cantidad NUMBER,
    precio_unitario NUMBER(10,2),
    subtotal NUMBER(10,2),
    estado NUMBER DEFAULT 1,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- registro del movimiento
    fecha_modificacion TIMESTAMP,                       -- actualización del registro
    accion VARCHAR2(10) NOT NULL,                       -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                            -- origen de la operación
);

-- Documentación de la tabla de bitácora
COMMENT ON TABLE detalle_pedido_bit IS 'Tabla de bitacora que registra los movimientos realizados sobre el detalle de pedidos';
COMMENT ON COLUMN detalle_pedido_bit.id_detalle_bit IS 'Identificador único de la bitácora';
COMMENT ON COLUMN detalle_pedido_bit.id_detalle IS 'ID del detalle de pedido ';
COMMENT ON COLUMN detalle_pedido_bit.id_pedido IS 'ID del pedido asociado al detalle';
COMMENT ON COLUMN detalle_pedido_bit.id_producto IS 'ID del producto asociado al detalle del pedido';
COMMENT ON COLUMN detalle_pedido_bit.cantidad IS 'Cantidad del producto ';
COMMENT ON COLUMN detalle_pedido_bit.precio_unitario IS 'Precio unitario del producto ';
COMMENT ON COLUMN detalle_pedido_bit.subtotal IS 'Subtotal calculado del detalle del pedido';
COMMENT ON COLUMN detalle_pedido_bit.estado IS 'Estado del registro (activo/inactivo)';
COMMENT ON COLUMN detalle_pedido_bit.fecha_creacion IS 'Fecha en la que se registró el movimiento en la bitácora';
COMMENT ON COLUMN detalle_pedido_bit.fecha_modificacion IS 'Fecha en la que se modificó el registro en la bitácora';
COMMENT ON COLUMN detalle_pedido_bit.accion IS 'Tipo de operación realizada: INSERT, UPDATE o DELETE';
COMMENT ON COLUMN detalle_pedido_bit.ip IS 'Dirección IP desde donde se realizó la operación';

-- Registra en bitácora las inserciones y modificaciones de detalle_pedido
CREATE OR REPLACE TRIGGER TRG_DETALLE_PEDIDO_AUD
AFTER INSERT OR UPDATE ON DETALLE_PEDIDO
FOR EACH ROW
DECLARE

    V_ACCION VARCHAR2(20);

    V_ID_BIT NUMBER;

    V_FECHA_CREACION TIMESTAMP := NULL;

    V_FECHA_MODIFICACION TIMESTAMP := NULL;

BEGIN

    -- Obtener ID de bitácora
    SELECT SEQ_DETALLE_PEDIDO_BIT.NEXTVAL
    INTO V_ID_BIT
    FROM DUAL;

    -- Inserción
    IF INSERTING THEN

        V_ACCION := 'INSERT';
        V_FECHA_CREACION := SYSTIMESTAMP;

    -- Actualización
    ELSIF UPDATING THEN

        V_FECHA_CREACION := SYSTIMESTAMP;
        V_FECHA_MODIFICACION := SYSTIMESTAMP;

        IF :OLD.ESTADO = 1 AND :NEW.ESTADO = 0 THEN

            V_ACCION := 'INACTIVE';

        ELSIF :OLD.ESTADO = 0 AND :NEW.ESTADO = 1 THEN

            V_ACCION := 'ACTIVE';

        ELSE

            V_ACCION := 'UPDATE';

        END IF;

    END IF;

    INSERT INTO DETALLE_PEDIDO_BIT
    (
        ID_DETALLE_BIT,
        ID_DETALLE,
        ID_PEDIDO,
        ID_PRODUCTO,
        CANTIDAD,
        PRECIO_UNITARIO,
        SUBTOTAL,
        ESTADO,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES
    (
        V_ID_BIT,
        :NEW.ID_DETALLE,
        :NEW.ID_PEDIDO,
        :NEW.ID_PRODUCTO,
        :NEW.CANTIDAD,
        :NEW.PRECIO_UNITARIO,
        :NEW.SUBTOTAL,
        :NEW.ESTADO,
        V_FECHA_CREACION,
        V_FECHA_MODIFICACION,
        V_ACCION,
        NVL(
            SYS_CONTEXT('USERENV','IP_ADDRESS'),
            SYS_CONTEXT('USERENV','HOST')
        )
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