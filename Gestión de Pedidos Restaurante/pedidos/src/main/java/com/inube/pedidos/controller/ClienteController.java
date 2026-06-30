package com.inube.pedidos.controller;

import com.inube.pedidos.dto.ApiResponse;
import com.inube.pedidos.model.ClienteModel;
import com.inube.pedidos.service.ClienteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import static com.inube.pedidos.util.UtilConstants.*;

@RestController
@RequestMapping("/api/clientes")
@RequiredArgsConstructor
public class ClienteController {
    private final ClienteService service;

    @PostMapping
    public ResponseEntity<ApiResponse<?>> guardar (@RequestBody ClienteModel cliente){
        return ResponseEntity.ok(new ApiResponse<>(true,MSG8,service.guardar(cliente)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<?>> listar (){
        return ResponseEntity.ok(new ApiResponse<>(true,MSG1,service.listar()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> buscarPorId (@PathVariable Integer id){
        return ResponseEntity.ok(new ApiResponse<>(true,MSG1,service.buscarPorId(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> actualizar (@PathVariable Integer id, @RequestBody ClienteModel cliente){
        return ResponseEntity.ok(
                new ApiResponse<>(true,MSG9,service.actualizar(id,cliente)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> eliminar (@PathVariable Integer id){
        service.eliminar(id);
        return ResponseEntity.ok(new ApiResponse<>(true,MSG10,null));
    }

}
