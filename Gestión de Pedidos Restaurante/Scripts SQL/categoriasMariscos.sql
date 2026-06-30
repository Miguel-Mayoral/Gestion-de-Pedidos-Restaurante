
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE categorias CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_categorias';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
    -- Elimina la tabla de bitácora
    EXECUTE IMMEDIATE 'DROP TABLE categorias_bit CASCADE CONSTRAINTS ';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignora errores
END;
/


-- =============================================
-- TABLA CATEGORIAS
-- =============================================

CREATE TABLE categorias (
    id_categoria NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    descripcion VARCHAR2(200),
    estado NUMBER DEFAULT 1
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE categorias IS 'Tabla que almacena las categorias de productos';
COMMENT ON COLUMN categorias.id_categoria IS 'Identificador unico de la categoria (llave primaria)';
COMMENT ON COLUMN categorias.nombre IS 'Nombre de la categoria';
COMMENT ON COLUMN categorias.descripcion IS 'Descripcion de la categoria';
COMMENT ON COLUMN categorias.estado IS 'Estado de la categoria (1=Activa, 0=Inactiva)';

-- =============================================
-- SECUENCIAS
-- =============================================
CREATE SEQUENCE seq_categorias START WITH 1 INCREMENT BY 1;

-- Tabla de bitácora de categorías
CREATE TABLE categorias_bit (
    id_categoria_bit NUMBER PRIMARY KEY,   -- ID único de la bitácora
    id_categoria NUMBER NOT NULL,          -- ID de la categoría original

    nombre VARCHAR2(100),
    descripcion VARCHAR2(200),
    estado NUMBER DEFAULT 1,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- registro del movimiento
    fecha_modificacion TIMESTAMP,                        -- si hubo actualización
    accion VARCHAR2(10) NOT NULL,                        -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                             -- IP de origen
);

-- Documentación de la tabla de bitácora
COMMENT ON TABLE categorias_bit IS 'Tabla de bitacora que registra los movimientos realizados sobre las categorias';
COMMENT ON COLUMN categorias_bit.id_categoria_bit IS 'Identificador único de la bitácora';
COMMENT ON COLUMN categorias_bit.id_categoria IS 'ID de la categoría ';
COMMENT ON COLUMN categorias_bit.nombre IS 'Nombre de la categoría ';
COMMENT ON COLUMN categorias_bit.descripcion IS 'Descripción de la categoría ';
COMMENT ON COLUMN categorias_bit.estado IS 'Estado de la categoría (activo/inactivo)';
COMMENT ON COLUMN categorias_bit.fecha_creacion IS 'Fecha en la que se registró el movimiento en la bitácora';
COMMENT ON COLUMN categorias_bit.fecha_modificacion IS 'Fecha en la que se modificó el registro en la bitácora';
COMMENT ON COLUMN categorias_bit.accion IS 'Tipo de operación realizada: INSERT, UPDATE o DELETE';
COMMENT ON COLUMN categorias_bit.ip IS 'Dirección IP desde donde se realizó la operación';

-- Registra en bitácora las inserciones y modificaciones de categorías
CREATE OR REPLACE TRIGGER TRG_CATEGORIAS_AUD
AFTER INSERT OR UPDATE ON CATEGORIAS
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
    SELECT NVL(MAX(ID_CATEGORIA_BIT), 0) + 1
    INTO V_ID_BIT
    FROM CATEGORIAS_BIT;

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
    INSERT INTO CATEGORIAS_BIT (
        ID_CATEGORIA_BIT,
        ID_CATEGORIA,
        NOMBRE,
        DESCRIPCION,
        ESTADO,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES (
        V_ID_BIT,
        :NEW.ID_CATEGORIA,
        :NEW.NOMBRE,
        :NEW.DESCRIPCION,
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

