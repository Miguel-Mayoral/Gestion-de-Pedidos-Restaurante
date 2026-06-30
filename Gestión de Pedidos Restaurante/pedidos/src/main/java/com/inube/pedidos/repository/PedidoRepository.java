package com.inube.pedidos.repository;

import com.inube.pedidos.model.PedidoModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PedidoRepository extends JpaRepository<PedidoModel,Integer> {
    List<PedidoModel> findByClienteIdClienteAndEstado(Integer idCliente, Integer estado);
    List<PedidoModel> findByEstado(Integer estado);
}
