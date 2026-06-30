BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE roles CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ROLES_BIT';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE roles_bit CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/



CREATE TABLE roles (
id_rol NUMBER PRIMARY KEY,
nombre VARCHAR2(50) UNIQUE NOT NULL
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE roles IS 'Tabla que almacena los roles disponibles para los usuarios del sistema';

COMMENT ON COLUMN roles.id_rol IS 'Identificador unico del rol (llave primaria)';
COMMENT ON COLUMN roles.nombre IS 'Nombre unico del rol asignable a los usuarios';

-- Tabla de bitácora de roles
CREATE TABLE roles_bit (
    id_rol_bit NUMBER PRIMARY KEY,      -- ID único de la bitácora
    id_rol NUMBER NOT NULL,             -- ID del rol original

    nombre VARCHAR2(50),

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- registro del movimiento
    fecha_modificacion TIMESTAMP,                       -- actualización del registro
    accion VARCHAR2(10) NOT NULL,                       -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                            -- origen de la operación
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE roles_bit IS 'Tabla de bitacora que almacena los cambios realizados sobre los roles del sistema';

COMMENT ON COLUMN roles_bit.id_rol_bit IS 'Identificador unico del registro de bitacora';
COMMENT ON COLUMN roles_bit.id_rol IS 'Identificador del rol afectado';
COMMENT ON COLUMN roles_bit.nombre IS 'Nombre del rol registrado';
COMMENT ON COLUMN roles_bit.fecha_creacion IS 'Fecha y hora en que se registro el movimiento';
COMMENT ON COLUMN roles_bit.fecha_modificacion IS 'Fecha y hora de modificacion del registro';
COMMENT ON COLUMN roles_bit.accion IS 'Operacion realizada sobre el registro (INSERT, UPDATE o DELETE)';
COMMENT ON COLUMN roles_bit.ip IS 'Direccion IP desde donde se realizo la operacion';

-- Secuencia para la tabla de bitácora
CREATE SEQUENCE SEQ_ROLES_BIT
START WITH 1
INCREMENT BY 1;

-- Registra en bitácora las inserciones y modificaciones de roles
CREATE OR REPLACE TRIGGER TRG_ROLES_AUD
AFTER INSERT OR UPDATE ON ROLES
FOR EACH ROW
DECLARE
    -- Tipo de operación realizada
    V_ACCION VARCHAR2(20);

    -- Fecha de creación registrada en bitácora
    V_FECHA_CREACION TIMESTAMP := NULL;

    -- Fecha de modificación registrada en bitácora
    V_FECHA_MODIFICACION TIMESTAMP := NULL;

BEGIN

    -- Registro creado
    IF INSERTING THEN
        V_ACCION := 'INSERT';
        V_FECHA_CREACION := SYSTIMESTAMP;

    -- Registro modificado
    ELSIF UPDATING THEN
        V_ACCION := 'UPDATE';
        V_FECHA_CREACION := SYSTIMESTAMP;
        V_FECHA_MODIFICACION := SYSTIMESTAMP;
    END IF;

    -- Inserta el movimiento en la bitácora
    INSERT INTO ROLES_BIT (
        ID_ROL_BIT,
        ID_ROL,
        NOMBRE,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES (
        SEQ_ROLES_BIT.NEXTVAL,
        :NEW.ID_ROL,
        :NEW.NOMBRE,
        V_FECHA_CREACION,
        V_FECHA_MODIFICACION,
        V_ACCION,
        NVL(SYS_CONTEXT('USERENV', 'IP_ADDRESS'), 'LOCALHOST')
    );

END;
/