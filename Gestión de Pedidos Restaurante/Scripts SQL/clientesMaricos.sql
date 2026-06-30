
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE cliente CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_cliente';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    -- Elimina la tabla de bitácora
    EXECUTE IMMEDIATE 'DROP TABLE cliente_bit CASCADE CONSTRAINTS ';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignora errores
END;
/



-- =============================================
-- TABLA CLIENTES
-- =============================================

CREATE TABLE cliente (
    id_cliente NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    apellido VARCHAR2(100),
    telefono VARCHAR2(20),
    correo  VARCHAR2(150) UNIQUE,
    estado NUMBER DEFAULT 1,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE cliente IS 'Tabla que almacena la informacion de los clientes';
COMMENT ON COLUMN cliente.id_cliente IS 'Identificador unico del cliente (llave primaria)';
COMMENT ON COLUMN cliente.nombre IS 'Nombre del cliente';
COMMENT ON COLUMN cliente.apellido IS 'Apellido del cliente';
COMMENT ON COLUMN cliente.telefono IS 'Telefono de contacto del cliente';
COMMENT ON COLUMN cliente.correo IS 'Correo electronico unico del cliente';
COMMENT ON COLUMN cliente.estado IS 'Estado del cliente (1=Activo, 0=Inactivo)';
COMMENT ON COLUMN cliente.fecha_registro IS 'Fecha y hora en que se registro el cliente';

-- =============================================
-- SECUENCIAS
-- =============================================
CREATE SEQUENCE seq_cliente START WITH 1 INCREMENT BY 1;

-- Tabla de bitácora de clientes
CREATE TABLE cliente_bit (
    id_cliente_bit NUMBER PRIMARY KEY,   -- ID único de la bitácora
    id_cliente NUMBER NOT NULL,          -- ID del cliente original

    nombre VARCHAR2(100),
    apellido VARCHAR2(100),
    telefono VARCHAR2(20),
    correo VARCHAR2(150),

    estado NUMBER DEFAULT 1,
    fecha_registro TIMESTAMP,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- cuándo se registró el movimiento
    fecha_modificacion TIMESTAMP,                       -- cuándo se modificó el registro
    accion VARCHAR2(10) NOT NULL,                       -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                            -- IP de origen de la operación
);

-- Documentación de la tabla de bitácora
COMMENT ON TABLE cliente_bit IS 'Tabla de bitacora que registra los movimientos realizados sobre los clientes';
COMMENT ON COLUMN cliente_bit.id_cliente_bit IS 'Identificador único de la bitácora';
COMMENT ON COLUMN cliente_bit.id_cliente IS 'ID del cliente ';
COMMENT ON COLUMN cliente_bit.nombre IS 'Nombre del cliente';
COMMENT ON COLUMN cliente_bit.apellido IS 'Apellido del cliente';
COMMENT ON COLUMN cliente_bit.telefono IS 'Teléfono del cliente';
COMMENT ON COLUMN cliente_bit.correo IS 'Correo electrónico del cliente';
COMMENT ON COLUMN cliente_bit.estado IS 'Estado del registro del cliente (activo/inactivo)';
COMMENT ON COLUMN cliente_bit.fecha_registro IS 'Fecha original del registro del cliente';
COMMENT ON COLUMN cliente_bit.fecha_creacion IS 'Fecha en la que se registró el movimiento en la bitácora';
COMMENT ON COLUMN cliente_bit.fecha_modificacion IS 'Fecha en la que se modificó el registro en la bitácora';
COMMENT ON COLUMN cliente_bit.accion IS 'Tipo de operación realizada: INSERT, UPDATE o DELETE';
COMMENT ON COLUMN cliente_bit.ip IS 'Dirección IP desde donde se realizó la operación';


-- Registra en bitácora las inserciones y modificaciones de clientes
CREATE OR REPLACE TRIGGER TRG_CLIENTE_AUD
AFTER INSERT OR UPDATE ON CLIENTE
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
    SELECT NVL(MAX(ID_CLIENTE_BIT), 0) + 1
    INTO V_ID_BIT
    FROM CLIENTE_BIT;

    -- Registro creado
    IF INSERTING THEN
        V_ACCION := 'INSERT';
        V_FECHA_CREACION := SYSTIMESTAMP;

    -- Registro modificado
    ELSIF UPDATING THEN
        V_FECHA_MODIFICACION := SYSTIMESTAMP;
        V_FECHA_CREACION := SYSTIMESTAMP;

        -- Cliente desactivado
        IF :OLD.ESTADO = 1 AND :NEW.ESTADO = 0 THEN
            V_ACCION := 'INACTIVE';

        ELSIF :OLD.ESTADO = 0 AND :NEW.ESTADO = 1 THEN
            V_ACCION := 'ACTIVE';

        -- Actualización general
        ELSE
            V_ACCION := 'UPDATE';
        END IF;
    END IF;

    -- Inserta el movimiento en la bitácora
    INSERT INTO CLIENTE_BIT (
        ID_CLIENTE_BIT,
        ID_CLIENTE,
        NOMBRE,
        APELLIDO,
        TELEFONO,
        CORREO,
        ESTADO,
        FECHA_REGISTRO,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES (
        V_ID_BIT,
        :NEW.ID_CLIENTE,
        :NEW.NOMBRE,
        :NEW.APELLIDO,
        :NEW.TELEFONO,
        :NEW.CORREO,
        :NEW.ESTADO,
        :NEW.FECHA_REGISTRO,
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

