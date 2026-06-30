package com.inube.pedidos.repository;

import com.inube.pedidos.model.CategoriaModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoriaRepository extends JpaRepository<CategoriaModel,Integer> {
    List<CategoriaModel> findByEstado(Integer estado);
}
