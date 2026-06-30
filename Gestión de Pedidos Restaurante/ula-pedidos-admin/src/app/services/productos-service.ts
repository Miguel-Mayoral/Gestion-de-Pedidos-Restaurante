import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class ProductosService {
  private apiUrl = 'http://localhost:8080/api/productos';

  constructor(private http: HttpClient) {}

  listar(): Observable<any> {
    return this.http.get(this.apiUrl);
  }

  buscarPorId(id: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/${id}`);
  }

  guardar(producto: any): Observable<any> {
    return this.http.post(this.apiUrl, producto);
  }

  actualizar(id: number, producto: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}`, producto);
  }

  eliminar(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  // RF-06: Actualizar stock usando el PatchMapping que recibe un Map<String, Integer>
  actualizarStock(id: number, nuevoStock: number): Observable<any> {
    return this.http.patch(`${this.apiUrl}/${id}/stock`, { stock: nuevoStock });
  }
}
