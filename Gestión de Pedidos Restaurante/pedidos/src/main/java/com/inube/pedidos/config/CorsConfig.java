package com.inube.pedidos.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {

    @Bean
    public WebMvcConfigurer corsConfigurer(){
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")// Aplica a todos los endpoints que inicien con /api
                        .allowedOrigins("http://localhost:4200")//El puerto por defecto de angular
                        .allowedMethods("GET","POST","PUT","PATCH","DELETE","OPTIONS")//Metodos primitivos
                        .allowedHeaders("*")//Permite todos los encabezados
                        .allowCredentials(true);//Por si en el futuro usan cookies o sesiones
            }
        };
    }
}
