/*========================================================
  TABLA DE CAT_ROLES
========================================================*/
BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE cliente CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE categorias CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE productos CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE pedidos CASCADE CONSTRAINTS';
   EXECUTE IMMEDIATE 'DROP TABLE detalle_pedido CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_cliente';
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_categorias';
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_productos';
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_pedidos';
   EXECUTE IMMEDIATE 'DROP SEQUENCE seq_detalle_pedido';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- =============================================
-- SECUENCIAS
-- =============================================

--CREATE SEQUENCE seq_clientes START WITH 1 INCREMENT BY 1;
--CREATE SEQUENCE seq_categorias START WITH 1 INCREMENT BY 1;
--CREATE SEQUENCE seq_productos START WITH 1 INCREMENT BY 1;
--CREATE SEQUENCE seq_pedidos START WITH 1 INCREMENT BY 1;
--CREATE SEQUENCE seq_detalle_pedido START WITH 1 INCREMENT BY 1;







INSERT INTO categorias( id_categoria, nombre, descripcion )
VALUES( seq_categorias.NEXTVAL, 'Tacos','Tacos de mariscos');

INSERT INTO categorias(id_categoria, nombre, descripcion )
VALUES( seq_categorias.NEXTVAL, 'Bebidas','Bebidas preparadas');

INSERT INTO productos( id_producto, nombre, descripcion, precio, stock, url_imagen, id_categoria)
VALUES(
       seq_productos.NEXTVAL,
       'Taco Gobernador',
       'Taco de camarón',
       95,
       50,
       'https://i.blogs.es/ba0112/tacos-gobernador/650_1200.jpg',
       1);

INSERT INTO productos( id_producto, nombre, descripcion, precio, stock, url_imagen, id_categoria)
VALUES(
       seq_productos.NEXTVAL,
       'Agua de Horchata',
       'Bebida natural',
       35,
       100,
       'https://media.gq.com.mx/photos/673208b90bd4a888d68a1092/1:1/w_2000,h_2000,c_limit/Horchata.jpg',
       2);

INSERT INTO cliente( id_cliente, nombre, apellido, telefono, correo )
VALUES( seq_cliente.NEXTVAL,
       'Eduardo',
       'Sanchez',
       '4731305687',
       'admin@ulamariscos.com');

INSERT INTO cliente( id_cliente, nombre, apellido, telefono, correo )
VALUES( seq_cliente.NEXTVAL,
       'Uriel',
       'Gonzalez',
       '5531305687',
       'uriel@ulamariscos.com');

commit;

 select * from cliente;
 select * from cliente_bit;
 SELECT * FROM categorias;
 select * from productos;
 select * from pedidos;
 select * from detalle_pedido;

 select * from productos_bit;

SELECT seq_categorias.NEXTVAL FROM dual;

--
-- CREATE SEQUENCE seq_roles START WITH 1 INCREMENT BY 1;
-- CREATE SEQUENCE seq_usuarios START WITH 1 INCREMENT BY 1;
-- CREATE SEQUENCE seq_refresh_tokens START WITH 1 INCREMENT BY 1;

 select * from cliente;


INSERT INTO roles VALUES ( SEQ_ROLES_BIT.NEXTVAL, 'ROLE_ADMIN' );

INSERT INTO roles VALUES (SEQ_ROLES_BIT.NEXTVAL, 'ROLE_CLIENTE' );

COMMIT;


INSERT INTO usuarios (
    id_usuario,
    username,
    password,
    id_rol,
    id_cliente,
    estado
) VALUES (
    1,
    'admin',
    '$2a$10$7fEcHd5K86RN7/j200IIluBhNhxR7g.1Xv5JVJxMaw1o/g/HcHrCW',
    1,
    NULL,
    1
);
commit ;

select * from USUARIOS;

select * from ROLES;
select * from refresh_tokens;