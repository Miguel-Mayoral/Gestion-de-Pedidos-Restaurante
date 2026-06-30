
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE usuarios CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_USUARIOS_BIT';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE usuarios_bit CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/





-- =============================================
-- TABLA DETALLE USUARIOS
-- =============================================

CREATE TABLE usuarios (
id_usuario NUMBER PRIMARY KEY,
username VARCHAR2(150) UNIQUE NOT NULL,
password VARCHAR2(255) NOT NULL,
id_rol NUMBER NOT NULL,
id_cliente NUMBER,
estado NUMBER DEFAULT 1,

CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES roles(id_rol),
CONSTRAINT fk_usuario_cliente FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);


-- Documentación de la tabla y columnas
COMMENT ON TABLE usuarios IS 'Tabla que almacena las cuentas de usuario del sistema';

COMMENT ON COLUMN usuarios.id_usuario IS 'Identificador unico del usuario (llave primaria)';
COMMENT ON COLUMN usuarios.username IS 'Nombre de usuario utilizado para iniciar sesion';
COMMENT ON COLUMN usuarios.password IS 'Contrasena cifrada del usuario';
COMMENT ON COLUMN usuarios.id_rol IS 'Identificador del rol asignado al usuario (llave foranea a roles)';
COMMENT ON COLUMN usuarios.id_cliente IS 'Identificador del cliente asociado al usuario (llave foranea a clientes)';
COMMENT ON COLUMN usuarios.estado IS 'Estado del usuario (1=Activo, 0=Inactivo)';

-- Tabla de bitácora de usuarios
CREATE TABLE usuarios_bit (
    id_usuario_bit NUMBER PRIMARY KEY,    -- ID único de la bitácora
    id_usuario NUMBER NOT NULL,           -- ID del usuario original

    username VARCHAR2(150),
    password VARCHAR2(255),
    id_rol NUMBER,
    id_cliente NUMBER,
    estado NUMBER DEFAULT 1,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- registro del movimiento
    fecha_modificacion TIMESTAMP,                       -- actualización del registro
    accion VARCHAR2(10) NOT NULL,                       -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                            -- origen de la operación
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE usuarios_bit IS 'Tabla de bitacora que almacena los cambios realizados sobre los usuarios';

COMMENT ON COLUMN usuarios_bit.id_usuario_bit IS 'Identificador unico del registro de bitacora';
COMMENT ON COLUMN usuarios_bit.id_usuario IS 'Identificador del usuario afectado';
COMMENT ON COLUMN usuarios_bit.username IS 'Nombre de usuario registrado';
COMMENT ON COLUMN usuarios_bit.password IS 'Contrasena cifrada del usuario';
COMMENT ON COLUMN usuarios_bit.id_rol IS 'Rol asignado al usuario';
COMMENT ON COLUMN usuarios_bit.id_cliente IS 'Cliente asociado al usuario';
COMMENT ON COLUMN usuarios_bit.estado IS 'Estado del usuario (1=Activo, 0=Inactivo)';
COMMENT ON COLUMN usuarios_bit.fecha_creacion IS 'Fecha y hora en que se registro el movimiento';
COMMENT ON COLUMN usuarios_bit.fecha_modificacion IS 'Fecha y hora de modificacion del registro';
COMMENT ON COLUMN usuarios_bit.accion IS 'Operacion realizada sobre el registro (INSERT, UPDATE o DELETE)';
COMMENT ON COLUMN usuarios_bit.ip IS 'Direccion IP desde donde se realizo la operacion';


--CREATE SEQUENCE seq_usuarios START WITH 1 INCREMENT BY 1;

-- Secuencia para la tabla de bitácora
CREATE SEQUENCE SEQ_USUARIOS_BIT
START WITH 1
INCREMENT BY 1;

-- Registra en bitácora las inserciones y modificaciones de usuarios
CREATE OR REPLACE TRIGGER TRG_USUARIOS_AUD
AFTER INSERT OR UPDATE ON USUARIOS
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
        V_FECHA_MODIFICACION := SYSTIMESTAMP;
        V_FECHA_CREACION := SYSTIMESTAMP;

        -- Cambio de estado
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
    INSERT INTO USUARIOS_BIT (
        ID_USUARIO_BIT,
        ID_USUARIO,
        USERNAME,
        PASSWORD,
        ID_ROL,
        ID_CLIENTE,
        ESTADO,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES (
        SEQ_USUARIOS_BIT.NEXTVAL,
        :NEW.ID_USUARIO,
        :NEW.USERNAME,
        :NEW.PASSWORD,
        :NEW.ID_ROL,
        :NEW.ID_CLIENTE,
        :NEW.ESTADO,
        V_FECHA_CREACION,
        V_FECHA_MODIFICACION,
        V_ACCION,
        NVL(SYS_CONTEXT('USERENV', 'IP_ADDRESS'), 'LOCALHOST')
    );

END;
/
