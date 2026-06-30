package com.inube.pedidos.repository;


import com.inube.pedidos.model.ProductoModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ProductoRepository extends JpaRepository<ProductoModel,Integer> {
    List<ProductoModel> findByEstado(Integer estado);
}

