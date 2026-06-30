package com.inube.pedidos.controller;

import com.inube.pedidos.dto.ApiResponse;
import com.inube.pedidos.model.ProductoModel;
import com.inube.pedidos.service.ProductoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;

import static com.inube.pedidos.util.UtilConstants.*;

@RestController
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService service;

    @PostMapping
    public ResponseEntity<ApiResponse<?>> guardar(@RequestBody ProductoModel producto){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG2, service.guardar(producto)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<?>> listar(){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG1, service.listar()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> buscarPorId(@PathVariable Integer id){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG1, service.buscarPorId(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> actualizar(@PathVariable Integer id, @RequestBody ProductoModel producto){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG3, service.actualizar(id, producto)));
    }

    @PutMapping("/{id}/stock")
    public ResponseEntity<ApiResponse<?>> actualizarStock(
            @PathVariable Integer id,
            @RequestBody HashMap<String, Integer> request){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG4, service.actualizarStock(id, request.get(CODE1))));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> eliminar(@PathVariable Integer id){
        service.eliminar(id);
        return ResponseEntity.ok(new ApiResponse<>(true, MSG5, null));
    }
}