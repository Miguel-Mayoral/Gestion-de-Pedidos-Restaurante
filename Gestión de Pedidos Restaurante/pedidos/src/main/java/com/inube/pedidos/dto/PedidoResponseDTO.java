package com.inube.pedidos.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
public class PedidoResponseDTO {
    private Integer idPedido;
    private Integer idCliente;
    private LocalDateTime fechaPedido;
    private BigDecimal total;
    private String estadoPedido;
    private Integer estado;
    private List<DetallePedidoResponseDTO> detalles;
}

