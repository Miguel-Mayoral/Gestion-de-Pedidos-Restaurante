package com.inube.pedidos.controller;

import com.inube.pedidos.dto.ApiResponse;
import com.inube.pedidos.model.CategoriaModel;
import com.inube.pedidos.service.CategoriaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import static com.inube.pedidos.util.UtilConstants.*;

@RestController
@RequestMapping("/api/categorias")
@RequiredArgsConstructor
public class CategoriaController {
    private final CategoriaService service;

    @PostMapping
    public ResponseEntity<ApiResponse<?>> guardar (@RequestBody CategoriaModel categoria){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG11,service.guardar(categoria)));
    }


    @GetMapping
    public ResponseEntity<ApiResponse<?>> listar(){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG1,service.listar()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> buscarPorId (@PathVariable Integer id) {
        return ResponseEntity.ok(new ApiResponse<>(true, MSG1, service.buscarPorId(id)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> actualizar(@PathVariable Integer id,@RequestBody CategoriaModel categoria){
        return  ResponseEntity.ok(new ApiResponse<>(true,MSG12,service.actualizar(id,categoria)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<?>> eliminar(@PathVariable Integer id){
        service.eliminar(id);
        return ResponseEntity.ok(new ApiResponse<>(true, MSG2,null));
    }

}
