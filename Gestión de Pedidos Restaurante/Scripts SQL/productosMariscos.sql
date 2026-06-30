
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE productos CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_productos';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    -- Elimina la tabla de bitácora
    EXECUTE IMMEDIATE 'DROP TABLE productos_bit CASCADE CONSTRAINTS ';
EXCEPTION
    WHEN OTHERS THEN NULL; -- Ignora errores
END;
/

-- =============================================
-- TABLA PRODUCTOS
-- =============================================

CREATE TABLE productos (
    id_producto NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    descripcion VARCHAR2(200),
    precio NUMBER(10,2),
    stock NUMBER,
    url_imagen VARCHAR2(500),
    id_categoria NUMBER,
    estado NUMBER DEFAULT 1,

    CONSTRAINT fk_producto_categoria
    FOREIGN KEY(id_categoria)
    REFERENCES categorias(id_categoria)
);

-- Documentación de la tabla y columnas
COMMENT ON TABLE productos IS 'Tabla que almacena los productos disponibles en el sistema';
COMMENT ON COLUMN productos.id_producto IS 'Identificador unico del producto (llave primaria)';
COMMENT ON COLUMN productos.nombre IS 'Nombre del producto';
COMMENT ON COLUMN productos.descripcion IS 'Descripcion del producto';
COMMENT ON COLUMN productos.precio IS 'Precio del producto';
COMMENT ON COLUMN productos.stock IS 'Cantidad disponible en inventario';
COMMENT ON COLUMN productos.url_imagen IS 'URL de la imagen del producto';
COMMENT ON COLUMN productos.id_categoria IS 'Identificador de la categoria (llave foranea a categorias)';
COMMENT ON COLUMN productos.estado IS 'Estado del producto (1=Activo, 0=Inactivo)';

-- =============================================
-- SECUENCIAS
-- =============================================
CREATE SEQUENCE seq_productos START WITH 1 INCREMENT BY 1;

-- Tabla de bitácora de productos
CREATE TABLE productos_bit (
    id_producto_bit NUMBER PRIMARY KEY,   -- ID único de la bitácora
    id_producto NUMBER NOT NULL,          -- ID del producto original

    nombre VARCHAR2(100),
    descripcion VARCHAR2(200),
    precio NUMBER(10,2),
    stock NUMBER,
    url_imagen VARCHAR2(500),
    id_categoria NUMBER,
    estado NUMBER DEFAULT 1,

    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- registro del movimiento
    fecha_modificacion TIMESTAMP,                       -- actualización del registro
    accion VARCHAR2(10) NOT NULL,                       -- INSERT / UPDATE / DELETE
    ip VARCHAR2(30) NOT NULL                            -- origen de la operación
);

-- Documentación de la tabla de bitácora
COMMENT ON TABLE productos_bit IS 'Tabla de bitacora que registra los movimientos realizados sobre los productos';
COMMENT ON COLUMN productos_bit.id_producto_bit IS 'Identificador único de la bitácora';
COMMENT ON COLUMN productos_bit.id_producto IS 'ID del producto ';
COMMENT ON COLUMN productos_bit.nombre IS 'Nombre del producto ';
COMMENT ON COLUMN productos_bit.descripcion IS 'Descripción del producto ';
COMMENT ON COLUMN productos_bit.precio IS 'Precio del producto ';
COMMENT ON COLUMN productos_bit.stock IS 'Stock del producto ';
COMMENT ON COLUMN productos_bit.url_imagen IS 'URL de la imagen del producto ';
COMMENT ON COLUMN productos_bit.id_categoria IS 'ID de la categoría asociada al producto ';
COMMENT ON COLUMN productos_bit.estado IS 'Estado del producto (activo/inactivo)';
COMMENT ON COLUMN productos_bit.fecha_creacion IS 'Fecha en la que se registró el movimiento en la bitácora';
COMMENT ON COLUMN productos_bit.fecha_modificacion IS 'Fecha en la que se modificó el registro en la bitácora';
COMMENT ON COLUMN productos_bit.accion IS 'Tipo de operación realizada: INSERT, UPDATE o DELETE';
COMMENT ON COLUMN productos_bit.ip IS 'Dirección IP desde donde se realizó la operación';

-- Registra en bitácora las inserciones y modificaciones de productos
CREATE OR REPLACE TRIGGER TRG_PRODUCTOS_AUD
AFTER INSERT OR UPDATE ON PRODUCTOS
FOR EACH ROW
DECLARE
    -- Tipo de operación realizada
    V_ACCION VARCHAR2(20);

    -- ID para la bitácora
    V_ID_BIT NUMBER;

    -- Fecha de creación registrada en bitácora
    V_FECHA_CREACION TIMESTAMP := NULL;

    -- Fecha de modificación registrada en bitácora
    V_FECHA_MODIFICACION TIMESTAMP := NULL;

BEGIN
    -- Generar ID de bitácora (sin secuencia)
    SELECT NVL(MAX(ID_PRODUCTO_BIT), 0) + 1
    INTO V_ID_BIT
    FROM PRODUCTOS_BIT;

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
    INSERT INTO PRODUCTOS_BIT (
        ID_PRODUCTO_BIT,
        ID_PRODUCTO,
        NOMBRE,
        DESCRIPCION,
        PRECIO,
        STOCK,
        URL_IMAGEN,
        ID_CATEGORIA,
        ESTADO,
        FECHA_CREACION,
        FECHA_MODIFICACION,
        ACCION,
        IP
    )
    VALUES (
        V_ID_BIT,                 -- ID generado manualmente
        :NEW.ID_PRODUCTO,
        :NEW.NOMBRE,
        :NEW.DESCRIPCION,
        :NEW.PRECIO,
        :NEW.STOCK,
        :NEW.URL_IMAGEN,
        :NEW.ID_CATEGORIA,
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