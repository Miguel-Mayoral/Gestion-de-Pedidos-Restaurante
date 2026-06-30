import { ChangeDetectorRef, Component, inject, OnInit, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms'; // <-- IMPORTANTE: Agregar FormsModule en los imports de tu componente
import { PedidosService } from '../../services/pedidos-service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-pedidos-comp',
  standalone: true,
  imports: [CommonModule, FormsModule], // <-- Incluye FormsModule para el buscador [(ngModel)]
  templateUrl: './pedidos-comp.html',
})
export class PedidosComp implements OnInit {
  private platformId = inject(PLATFORM_ID);
  private cdr = inject(ChangeDetectorRef);
  private pedidosService = inject(PedidosService);

  pedidosExistentes: any[] = [];
  pedidosFiltrados: any[] = []; // Es mejor usar un segundo arreglo para no perder la lista original al buscar

  filtroEstadoSeleccionado: string = 'TODOS'; // Controla la pestaña activa ('TODOS', '1', '0')
  busquedaId: number | null = null;

  ngOnInit(): void {
    if (isPlatformBrowser(this.platformId)) {
      this.cargarMonitoreoGlobal();
    }
  }

  // Carga principal combinada con el filtro de estado de la base de datos
  cargarMonitoreoGlobal(): void {
    if (this.filtroEstadoSeleccionado === 'TODOS') {
      this.pedidosService.listarTodos().subscribe({
        next: (res: any) => {
          this.pedidosExistentes = res.data;
          this.pedidosFiltrados = res.data;
          this.cdr.detectChanges(); // Renderizado instantáneo inicial
        },
        error: () => console.error('Error al cargar comensales globales'),
      });
    } else {
      const estadoNumerico = parseInt(this.filtroEstadoSeleccionado);
      this.pedidosService.listarPorEstado(estadoNumerico).subscribe({
        next: (res: any) => {
          this.pedidosExistentes = res.data;
          this.pedidosFiltrados = res.data;
          this.cdr.detectChanges(); // Renderizado instantáneo al cambiar de pestaña
        },
        error: () => console.error('Error al filtrar pedidos por estado'),
      });
    }
  }

  // Cambiar de pestaña (Todos, Activos, Inactivos)
  cambiarFiltroEstado(nuevoEstado: string): void {
    this.filtroEstadoSeleccionado = nuevoEstado;
    this.busquedaId = null; // Limpiamos el buscador de ID al cambiar de sección
    this.cargarMonitoreoGlobal();
  }

  // Filtrar por ID en el cliente de manera rápida
  buscarPorId(): void {
    if (!this.busquedaId) {
      this.pedidosFiltrados = this.pedidosExistentes;
      this.cdr.detectChanges();
      return;
    }

    this.pedidosFiltrados = this.pedidosExistentes.filter((p) => p.idPedido === this.busquedaId);
    this.cdr.detectChanges(); // Muestra solo la comanda buscada al instante
  }

  // RF-09: Cancelación con renderizado inmediato garantizado
  cancelarOrden(idPedido: number): void {
    Swal.fire({
      title: '¿Cancelar este pedido permanentemente?',
      text: 'Esta acción ejecutará un borrado lógico en la base de datos y devolverá el stock.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      confirmButtonText: 'Sí, cancelar orden',
      cancelButtonText: 'Regresar',
    }).then((result) => {
      if (result.isConfirmed) {
        this.pedidosService.cancelarPedido(idPedido).subscribe({
          next: (res: any) => {
            Swal.fire('Cancelado', 'El estado del pedido cambió a inactivo.', 'success');

            // Re-ejecutamos la carga global. Al responder el servidor,
            // traerá los datos actualizados y el detectChanges() interno re-pintará la pantalla.
            this.cargarMonitoreoGlobal();
          },
          error: () => Swal.fire('Error', 'No se pudo dar de baja el pedido', 'error'),
        });
      }
    });
  }
}
