package com.inube.pedidos.model;


import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;

@Entity
@Table(name = "productos")
@Data
public class ProductoModel {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "seq_productos")
    @SequenceGenerator(name = "seq_productos",sequenceName = "seq_productos",allocationSize = 1)
    @Column (name = "id_producto")
    private Integer idProducto;

    @Column(name = "nombre")
    private String nombre;

    @Column(name = "descripcion")
    private String descripcion;

    @Column (name = "precio")
    private BigDecimal precio;

    @Column (name = "stock")
    private Integer stock;

    @Column(name = "url_imagen")
    private String urlImagen;

    @Column (name = "estado")
    private Integer estado = 1;

    @ManyToOne
    @JoinColumn (name = "id_categoria")
    private CategoriaModel categoria;
}
