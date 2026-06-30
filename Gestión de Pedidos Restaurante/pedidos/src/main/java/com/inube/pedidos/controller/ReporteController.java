package com.inube.pedidos.controller;


import com.inube.pedidos.dto.ApiResponse;
import com.inube.pedidos.repository.DetallePedidoRepository;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


import static com.inube.pedidos.util.UtilConstants.MSG1;

@RestController
@RequestMapping("/api/reportes")
@RequiredArgsConstructor
@Tag(name = "Reportes",description = "Reportes de ventas")
public class ReporteController {
    private final DetallePedidoRepository repository;

    @GetMapping("/top-vendidos")
    public ResponseEntity<ApiResponse<?>> topVendidos(){
        return ResponseEntity.ok(new ApiResponse<>(true, MSG1,repository.topVendidos()));
    }
}
