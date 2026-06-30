import { ChangeDetectorRef, Component, inject, OnInit, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ClientesService } from '../../services/clientes-service';
import { ProductosService } from '../../services/productos-service'; // <-- IMPORTAR
import { CategoriasService } from '../../services/categorias-service'; // <-- IMPORTAR
import { PedidosService } from '../../services/pedidos-service'; // <-- IMPORTAR
import { Router } from '@angular/router';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-dashboard-comp',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './dashboard-comp.html',
})
export class DashboardComp implements OnInit {
  // Inyectamos el ID de la plataforma usando el nuevo patrón inject de Angular
  private platformId = inject(PLATFORM_ID);
  private cdr = inject(ChangeDetectorRef);

  usuarioLogeado: any;
  categorias: any[] = [];
  productos: any[] = [];
  productosFiltrados: any[] = [];
  idCategoriaSeleccionada: string = '';

  carrito: any[] = [];
  totalCarrito: number = 0;
  historialPedidos: any[] = [];

  constructor(
    public authService: ClientesService,
    private prodService: ProductosService,
    private catService: CategoriasService,
    private pedService: PedidosService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.usuarioLogeado = this.authService.getSession();

    if (isPlatformBrowser(this.platformId)) {
      this.cargarCategorias();
      this.cargarProductos();
      this.cargarHistorialPedidos();
      this.cdr.detectChanges();
    }
  }

  cargarCategorias(): void {
    this.catService.listar().subscribe({
      next: (res: any) => {
        this.categorias = res.data;
        this.cdr.detectChanges(); // <-- Forzar renderizado inmediato de las categorías al entrar
      },
      error: () => console.error('Error al cargar categorías'),
    });
  }

  cargarProductos(): void {
    this.prodService.listar().subscribe({
      next: (res: any) => {
        this.productos = res.data;
        this.productosFiltrados = res.data;
        this.cdr.detectChanges(); // <-- SOLUCIÓN: Obliga a Angular a pintar los productos de inmediato sin dar clics
      },
      error: () => console.error('Error al cargar productos'),
    });
    this.cdr.detectChanges();
  }

  cargarHistorialPedidos(): void {
    if (this.usuarioLogeado && this.usuarioLogeado.idCliente) {
      this.pedService.listarPorCliente(this.usuarioLogeado.idCliente).subscribe({
        next: (res: any) => {
          this.historialPedidos = res.data;
          this.cdr.detectChanges(); // <-- Forzar renderizado inmediato del historial
        },
        error: () => console.error('Error al cargar el historial de pedidos'),
      });
    }
  }

  filtrarPorCategoria(): void {
    if (!this.idCategoriaSeleccionada) {
      this.productosFiltrados = this.productos;
    } else {
      this.productosFiltrados = this.productos.filter(
        (p) => p.categoria?.idCategoria === +this.idCategoriaSeleccionada,
      );
    }
    this.cdr.detectChanges();
  }

  agregarAlCarrito(producto: any): void {
    const firest = this.carrito.find((item) => item.idProducto === producto.idProducto);
    if (firest) {
      if (firest.cantidad >= producto.stock) {
        Swal.fire('Sin Stock', 'No puedes agregar más unidades de las disponibles', 'warning');
        return;
      }
      firest.cantidad++;
    } else {
      this.carrito.push({ ...producto, cantidad: 1 });
    }
    this.calcularTotal();
    this.cdr.detectChanges();
  }
  //Como vas Aremi?
  calcularTotal(): void {
    this.totalCarrito = this.carrito.reduce((acc, item) => acc + item.precio * item.cantidad, 0);
  }

  eliminarDelCarrito(id: number): void {
    this.carrito = this.carrito.filter((item) => item.idProducto !== id);
    this.calcularTotal();
    this.cdr.detectChanges();
  }

  limpiarCarrito(): void {
    this.carrito = [];
    this.totalCarrito = 0;
    this.cdr.detectChanges();
  }

  hacerPedido(): void {
    if (this.carrito.length === 0) return;

    Swal.fire({
      title: '¿Confirmar Pedido?',
      text: `El total de tu orden es de $${this.totalCarrito}`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Sí, ordenar',
      cancelButtonText: 'Cancelar',
    }).then((result) => {
      if (result.isConfirmed) {
        const pedidoRequest = {
          idCliente: this.usuarioLogeado.idCliente,
          productos: this.carrito.map((item) => ({
            idProducto: item.idProducto,
            cantidad: item.cantidad,
          })),
        };

        this.pedService.generarPedido(pedidoRequest).subscribe({
          next: (res: any) => {
            Swal.fire('¡Éxito!', 'Tu orden se ha mandado a la cocina.', 'success');

            // !!! AQUÍ EJECUTAMOS LA LIMPIEZA !!!
            this.limpiarCarrito();

            this.cargarHistorialPedidos(); // Para que aparezca el nuevo pedido en su historial
            this.cargarProductos(); // Para actualizar los números de stock en la pantalla
          },
          error: () => Swal.fire('Error', 'No se pudo procesar tu pedido', 'error'),
        });
      }
    });
  }

  repetirPedido(pedidoViejo: any): void {
    this.carrito = pedidoViejo.detalles.map((det: any) => ({
      idProducto: det.idProducto,
      nombre: det.nombreProducto,
      precio: det.precioUnitario,
      cantidad: det.cantidad,
    }));
    this.calcularTotal();
    Swal.fire('Carrito Actualizado', 'Se han cargado los productos del pedido anterior.', 'info');
  }
}
