import { Injectable, inject, PLATFORM_ID } from '@angular/core'; // <-- Importar inject y PLATFORM_ID
import { isPlatformBrowser } from '@angular/common'; // <-- Importar isPlatformBrowser
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

//Con Angular moderno el código se ejecuta en dos lugares:
//
// En el Servidor: Crea la estructura HTML básica inicial (aquí localStorage o window no existen).
//
// En el Navegador (Cliente): Ocurre la "hidratación", donde Angular toma el control de la página e interactúa con las
// APIs del navegador como el almacenamiento local. ¡Con isPlatformBrowser controlamos con precisión quirúrgica ese flujo!

@Injectable({
  providedIn: 'root',
})
export class ClientesService {
  private apiUrl = 'http://localhost:8080/api/clientes';
  private http = inject(HttpClient);
  private platformId = inject(PLATFORM_ID); // <-- Inyectar el ID de la plataforma

  listarClientes(): Observable<any> {
    return this.http.get(this.apiUrl);
  }

  registrarCliente(cliente: any): Observable<any> {
    return this.http.post(this.apiUrl, cliente);
  }
  eliminarPedidoDefinitivo(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  // --- Lógica de Sesión Educativa Protegida ---
  setSession(user: any): void {
    if (isPlatformBrowser(this.platformId)) {
      // <-- Validar que sea el navegador
      localStorage.setItem('user_session', JSON.stringify(user));
    }
  }

  getSession(): any {
    // Si se ejecuta en el servidor, devolvemos null temporalmente para evitar el crash
    if (isPlatformBrowser(this.platformId)) {
      const user = localStorage.getItem('user_session');
      return user ? JSON.parse(user) : null;
    }
    return null;
  }

  isLoggedIn(): boolean {
    return this.getSession() !== null;
  }

  isAdmin(): boolean {
    const user = this.getSession();
    return user && user.correo === 'admin@ulamariscos.com';
  }

  logout(): void {
    if (isPlatformBrowser(this.platformId)) {
      localStorage.removeItem('user_session');
    }
  }
}
