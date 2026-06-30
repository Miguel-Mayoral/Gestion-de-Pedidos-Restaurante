package com.inube.pedidos.exception;

import com.inube.pedidos.dto.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler (Exception.class)
    public ResponseEntity<ApiResponse<?>>manejarError(Exception e){

        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(
                        new ApiResponse<>(
                                false,
                                e.getMessage(),
                                null
                        )
                );
    }
}
