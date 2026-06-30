package com.inube.pedidos.controller;


import com.inube.pedidos.dto.ApiResponse;
import com.inube.pedidos.dto.PedidoRequest;
import com.inube.pedidos.dto.PedidoResponseDTO;
import com.inube.pedidos.service.PedidoService;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static com.inube.pedidos.util.UtilConstants.*;

@RestController
@RequestMapping("/api/pedidos")
@RequiredArgsConstructor
@Tag(name = "Pedidos",description = "Operacion de pedidos")
public class PedidoController {
    private final PedidoService service;

    @PostMapping
    public ResponseEntity<ApiResponse<?>> generarPedido (@RequestBody PedidoRequest request){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG6,service.generarPedido(request)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> cancelarPedido(@PathVariable Integer id){
        service.cancelarPedido(id);
        return ResponseEntity.ok(new ApiResponse<>(true, MSG7,null));
    }

    @GetMapping("/cliente/{idCliente}")
    public ResponseEntity<ApiResponse<List<PedidoResponseDTO>>> listarPorCliente(@PathVariable Integer idCliente){
        List<PedidoResponseDTO> pedidos = service.listarPedidosPorCliente(idCliente);
        return ResponseEntity.ok(new ApiResponse<>(true, MSG1,pedidos));
    }

    //1.Filtrar por todos los pedidos del sistema
    @GetMapping
    public ResponseEntity<ApiResponse<List<PedidoResponseDTO>>> listarTodos () {
        List<PedidoResponseDTO> lista = service.listarTodos();
        return ResponseEntity.ok(new ApiResponse<>(true, MSG1, lista));
    }

    //2. Filtrar por estado especifico
    @GetMapping("/estado/{estado}")
    public ResponseEntity<ApiResponse<?>> listarPorEstado(@PathVariable Integer estado){
        List<PedidoResponseDTO> lista = service.listarPorEstado( estado );
        return  ResponseEntity.ok(new ApiResponse<>(true,MSG1,lista));
    }
}
