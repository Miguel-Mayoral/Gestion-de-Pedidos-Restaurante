import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class PedidosService {
  private apiUrl = 'http://localhost:8080/api/pedidos';

  constructor(private http: HttpClient) {}

  generarPedido(pedidoRequest: any): Observable<any> {
    return this.http.post(this.apiUrl, pedidoRequest);
  }

  listarPorCliente(idCliente: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/cliente/${idCliente}`);
  }

  // RF-09: Borrado lógico del pedido
  cancelarPedido(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }
  listarTodos(): Observable<any> {
    return this.http.get(this.apiUrl);
  }

  listarPorEstado(estado: number): Observable<any> {
    return this.http.get(`${this.apiUrl}/estado/${estado}`);
  }
}
