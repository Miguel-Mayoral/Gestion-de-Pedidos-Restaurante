package com.inube.pedidos.service;


import com.inube.pedidos.model.ProductoModel;
import com.inube.pedidos.repository.ProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

import static com.inube.pedidos.util.UtilConstants.*;

@Service
@RequiredArgsConstructor
public class ProductoService {
    private final ProductoRepository repository;

    public ProductoModel guardar(ProductoModel producto){
        return repository.save(producto);}

    public List<ProductoModel> listar(){return repository.findByEstado(CODEPOS);}

    public ProductoModel buscarPorId(Integer id){
        return repository.findById(id).orElseThrow(()->new RuntimeException(MSG16));
    }

    public ProductoModel actualizar(Integer id, ProductoModel request){

         ProductoModel producto = buscarPorId(id);
         producto.setNombre(request.getNombre());
         producto.setDescripcion(request.getDescripcion());
         producto.setPrecio(request.getPrecio());
         producto.setStock(request.getStock());
         producto.setUrlImagen(request.getUrlImagen());
         producto.setCategoria(request.getCategoria());

         return repository.save(producto);
    }

    public ProductoModel actualizarStock(Integer id, Integer stock){

        ProductoModel producto = buscarPorId(id);
        producto.setStock(stock);
        return repository.save(producto);
    }

    public void eliminar(Integer id){

        ProductoModel producto = buscarPorId(id);
        producto.setEstado(CODENEG);
        repository.save(producto);
    }




}
