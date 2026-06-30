BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE refresh_tokens CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_REFRESH_TOKENS_BIT';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE refresh_tokens_bit CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/




-- =============================================
-- TABLA DETALLE REFRESH TOKENS
-- =============================================

CREATE TABLE refresh_tokens (
id_token NUMBER PRIMARY KEY,
token VARCHAR2(500) NOT NULL,
id_usuario NUMBER NOT NULL,
fecha_expiracion TIMESTAMP NOT NULL,
revocado NUMBER DEFAULT 0,

CONSTRAINT fk_refresh_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE refresh_tokens IS 'Tabla que almacena los tokens de actualización utilizados para mantener sesiones autenticadas mediante JWT';

COMMENT ON COLUMN refresh_tokens.id_token IS 'Identificador unico del refresh token (llave primaria)';
COMMENT ON COLUMN refresh_tokens.token IS 'Valor del refresh token generado para el usuario';
COMMENT ON COLUMN refresh_tokens.id_usuario IS 'Identificador del usuario propietario del token (llave foranea a usuarios)';
COMMENT ON COLUMN refresh_tokens.fecha_expiracion IS 'Fecha y hora de expiracion del refresh token';
COMMENT ON COLUMN refresh_tokens.revocado IS 'Indica si el token fue revocado (0=No, 1=Si)';


-- Tabla de bitácora de refresh tokens
CREATE TABLE refresh_tokens_bit (
    id_token_bit NUMBER PRIMARY KEY,     -- ID único de la bitácora
    id_token NUMBER NOT NULL,            -- ID del token original

    token VARCHAR2(500),
    id_usuario NUMBER,
    fecha_expiracion TIMESTAMP,
    revocado NUMBER DEFAULT 0,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- registro del movimiento
    fecha_modificacion TIMESTAMP,                       -- actualización del registro
    accion VARCHAR2(10) NOT NULL,                       -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                            -- origen de la operación
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE refresh_tokens_bit IS 'Tabla de bitacora que almacena los cambios realizados sobre los refresh tokens del sistema';

COMMENT ON COLUMN refresh_tokens_bit.id_token_bit IS 'Identificador unico del registro de bitacora';
COMMENT ON COLUMN refresh_tokens_bit.id_token IS 'Identificador del refresh token afectado';
COMMENT ON COLUMN refresh_tokens_bit.token IS 'Valor del refresh token registrado';
COMMENT ON COLUMN refresh_tokens_bit.id_usuario IS 'Identificador del usuario asociado al token';
COMMENT ON COLUMN refresh_tokens_bit.fecha_expiracion IS 'Fecha y hora de expiracion del token';
COMMENT ON COLUMN refresh_tokens_bit.revocado IS 'Estado del token (0=Activo, 1=Revocado)';
COMMENT ON COLUMN refresh_tokens_bit.fecha_creacion IS 'Fecha y hora en que se registro el movimiento';
COMMENT ON COLUMN refresh_tokens_bit.fecha_modificacion IS 'Fecha y hora de modificacion del registro';
COMMENT ON COLUMN refresh_tokens_bit.accion IS 'Operacion realizada sobre el registro (INSERT, UPDATE o DELETE)';
COMMENT ON COLUMN refresh_tokens_bit.ip IS 'Direccion IP desde donde se realizo la operacion';


-- Secuencia para la tabla de bitácora
CREATE SEQUENCE SEQ_REFRESH_TOKENS_BIT
START WITH 1
INCREMENT BY 1;

-- Registra en bitácora las inserciones y modificaciones de refresh tokens
CREATE OR REPLACE TRIGGER TRG_REFRESH_TOKENS_AUD
AFTER INSERT OR UPDATE ON REFRESH_TOKENS
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

        -- Cambio de estado de revocación
        IF :OLD.REVOCADO = 0 AND :NEW.REVOCADO = 1 THEN
            V_ACCION := 'REVOKED';

        ELSIF :OLD.REVOCADO = 1 AND :NEW.REVOCADO = 0 THEN
            V_ACCION := 'RESTORED';

        -- Actualización general
        ELSE
            V_ACCION := 'UPDATE';
        END IF;
    END IF;

    -- Inserta el movimiento en la bitácora
    INSERT INTO REFRESH_TOKENS_BIT (
        ID_TOKEN_BIT,
        ID_TOKEN,
        TOKEN,
        ID_USUARIO,
        FECHA_EXPIRACION,
        REVOCADO,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES (
        SEQ_REFRESH_TOKENS_BIT.NEXTVAL,
        :NEW.ID_TOKEN,
        :NEW.TOKEN,
        :NEW.ID_USUARIO,
        :NEW.FECHA_EXPIRACION,
        :NEW.REVOCADO,
        V_FECHA_CREACION,
        V_FECHA_MODIFICACION,
        V_ACCION,
        NVL(SYS_CONTEXT('USERENV', 'IP_ADDRESS'), 'LOCALHOST')
    );

END;
/