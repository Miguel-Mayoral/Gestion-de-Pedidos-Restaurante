package com.inube.pedidos.service;

import com.inube.pedidos.dto.DetallePedidoResponseDTO;
import com.inube.pedidos.dto.PedidoRequest;
import com.inube.pedidos.dto.PedidoResponseDTO;
import com.inube.pedidos.dto.ProductosPedidoDTO;
import com.inube.pedidos.model.ClienteModel;
import com.inube.pedidos.model.DetallePedidoModel;
import com.inube.pedidos.model.PedidoModel;
import com.inube.pedidos.model.ProductoModel;
import com.inube.pedidos.repository.ClienteRepository;
import com.inube.pedidos.repository.DetallePedidoRepository;
import com.inube.pedidos.repository.PedidoRepository;
import com.inube.pedidos.repository.ProductoRepository;
import com.inube.pedidos.util.UtilConstants;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

import static com.inube.pedidos.util.UtilConstants.*;

@Service
@RequiredArgsConstructor
public class PedidoService {

    private final PedidoRepository pedidoRepository;
    private final ClienteRepository clienteRepository;
    private final ProductoRepository productoRepository;
    private final DetallePedidoRepository detalleRepository;

    @Transactional
    public PedidoModel generarPedido(PedidoRequest request) {

        ClienteModel cliente =
                clienteRepository.findById(request.getIdCliente()).orElseThrow(() -> new RuntimeException(MSG15));

        PedidoModel pedido = new PedidoModel();
        pedido.setCliente(cliente);
        pedido.setEstadoPedido(CODE2);
        BigDecimal total = BigDecimal.ZERO;

        pedido = pedidoRepository.save(pedido);

        for (ProductosPedidoDTO item : request.getProductos()) {

            ProductoModel producto =
                    productoRepository.findById(item.getIdProducto()).orElseThrow(() -> new RuntimeException(MSG16));

            if (producto.getStock() < item.getCantidad()) {
                throw new RuntimeException(MSG17 + producto.getNombre());
            }

            BigDecimal subtotal = producto.getPrecio().multiply(BigDecimal.valueOf(item.getCantidad()));
            total = total.add(subtotal);

            DetallePedidoModel detalle = new DetallePedidoModel();

            detalle.setPedido(pedido);
            detalle.setProducto(producto);
            detalle.setCantidad(item.getCantidad());
            detalle.setPrecioUnitario(producto.getPrecio());
            detalle.setSubtotal(subtotal);

            detalleRepository.save(detalle);

            producto.setStock(producto.getStock() - item.getCantidad());

            productoRepository.save(producto);
        }

        pedido.setTotal(total);
        return pedidoRepository.save(pedido);
    }

    @Transactional
    public void cancelarPedido(Integer idPedido) {
        PedidoModel pedido = pedidoRepository.findById(idPedido).orElseThrow(() -> new RuntimeException(MSG18));
        pedido.setEstado(CODENEG);
        pedido.setEstadoPedido(CODE3);
        var detalles = detalleRepository.findByPedidoIdPedido(idPedido);
        for (DetallePedidoModel detalle : detalles) {

            ProductoModel producto = detalle.getProducto();
            producto.setStock(producto.getStock() + detalle.getCantidad());

            productoRepository.save(producto);
        }
        pedidoRepository.save(pedido);
    }

    public List<PedidoResponseDTO> listarPedidosPorCliente(Integer idCliente) {
        //1. Buscamos los pedidos activos del cliente(CODEPOS es 1 segun tus constantes)
        List<PedidoModel> pedidos = pedidoRepository.findByClienteIdClienteAndEstado(idCliente, UtilConstants.CODEPOS);

        //2. Mapeamos la lista de entidades a la lista de DTOs
        return pedidos.stream().map(pedido -> {
            PedidoResponseDTO dto = new PedidoResponseDTO();
            dto.setIdPedido(pedido.getIdPedido());
            dto.setFechaPedido(pedido.getFechaPedido());
            dto.setTotal(pedido.getTotal());
            dto.setEstadoPedido(pedido.getEstadoPedido());
            //Mapear los detalles de este pedido
            List<DetallePedidoResponseDTO> detallesDTO = pedido.getDetalles().stream()
                    .filter(d -> d.getEstado().equals(CODEPOS))//Solo detalles activos
                    .map(detalle -> {
                        DetallePedidoResponseDTO dDto = new DetallePedidoResponseDTO();
                        dDto.setIdDetalle(detalle.getIdDetalle());
                        dDto.setIdProducto(detalle.getProducto().getIdProducto());
                        dDto.setNombreProducto(detalle.getProducto().getNombre());
                        dDto.setCantidad(detalle.getCantidad());
                        dDto.setPrecioUnitario(detalle.getPrecioUnitario());
                        dDto.setSubtotal(detalle.getSubtotal());
                        return dDto;
                    }).toList();
            dto.setDetalles(detallesDTO);
            return dto;
        }).toList();
    }

    public List<PedidoResponseDTO> listarTodos(){
        List<PedidoModel> pedidos = pedidoRepository.findAll();
        return mapearAListaDTO(pedidos);
    }

    public List<PedidoResponseDTO> listarPorEstado(Integer estado){
        //Buscamos los pedidos por sue stado (0 a 1)
        List<PedidoModel> pedidos = pedidoRepository.findByEstado(estado);
        return mapearAListaDTO(pedidos);
    }

    //Metodo auxiliar privado para reutilizar el mapeo a DTO y no duplicar datos
    private List<PedidoResponseDTO> mapearAListaDTO(List<PedidoModel> pedidos){
        return pedidos.stream().map(pedido->{
            PedidoResponseDTO dto = new PedidoResponseDTO();
            dto.setIdPedido(pedido.getIdPedido());
            dto.setFechaPedido(pedido.getFechaPedido());
            dto.setTotal(pedido.getTotal());
            dto.setEstadoPedido(pedido.getEstadoPedido());
            dto.setIdCliente(pedido.getCliente().getIdCliente());
            dto.setEstado(pedido.getEstado());
            //Guardamos el estado numerico (0 a 1 ) en su propiedad si tu DTO lo tiene,
            //o simplemente confiamos en las relaciones.

            List<DetallePedidoResponseDTO> detallesDTO = pedido.getDetalles().stream()
                    .filter(d->d.getEstado().equals(CODEPOS))
                    .map(detalle ->{
                        DetallePedidoResponseDTO dDto = new DetallePedidoResponseDTO();
                        dDto.setIdDetalle(detalle.getIdDetalle());
                        dDto.setIdProducto(detalle.getProducto().getIdProducto());
                        dDto.setNombreProducto(detalle.getProducto().getNombre());
                        dDto.setCantidad(detalle.getCantidad());
                        dDto.setPrecioUnitario(detalle.getPrecioUnitario());
                        dDto.setSubtotal(detalle.getSubtotal());
                        return dDto;
                    }).toList();
            dto.setDetalles(detallesDTO);
            return dto;
        }).toList();
    }

}
