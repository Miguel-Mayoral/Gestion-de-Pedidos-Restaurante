import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { ClientesService } from '../services/clientes-service';
import Swal from 'sweetalert2';

export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(ClientesService);
  const router = inject(Router);

  if (!authService.isLoggedIn()) {
    Swal.fire('Acceso Denegado', 'Por favor inicia sesión primero.', 'warning');
    router.navigate(['/app/home']);
    return false;
  }

  const url = state.url;
  const isAdmin = authService.isAdmin();

  // Rutas que solo el Admin puede ver (permiso 'a' para admin, 'b' para cliente)
  const rutasAdmin = ['/app/pedidos', '/app/categorias', '/app/productos', '/app/clientes'];

  if (rutasAdmin.some((ruta) => url.includes(ruta)) && !isAdmin) {
    Swal.fire('No autorizado', 'No tienes permisos para gestionar este módulo.', 'error');
    router.navigate(['/app/dashboard']);
    return false;
  }

  return true;
};
