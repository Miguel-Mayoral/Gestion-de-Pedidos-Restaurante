import { ChangeDetectorRef, Component, inject, OnInit, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ProductosService } from '../../services/productos-service';
import { CategoriasService } from '../../services/categorias-service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-productos-comp',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './productos-comp.html',
})
export class ProductosComp implements OnInit {
  // Inyecciones modernas mediante la función inject()
  private platformId = inject(PLATFORM_ID);
  private cdr = inject(ChangeDetectorRef);

  productos: any[] = [];
  categorias: any[] = [];

  productoForm: any = {
    idProducto: null,
    nombre: '',
    descripcion: '',
    precio: 0,
    stock: 0,
    urlImagen: '',
    categoria: { idCategoria: null },
  };
  editando = false;

  constructor(
    private prodService: ProductosService,
    private catService: CategoriasService,
  ) {}

  ngOnInit(): void {
    // 1. Evitamos que el renderizado del servidor intente disparar las peticiones HTTP
    if (isPlatformBrowser(this.platformId)) {
      this.listarProductos();
      this.cargarCategorias();
    }
  }

  listarProductos(): void {
    this.prodService.listar().subscribe({
      next: (res: any) => {
        this.productos = res.data;
        // 2. Renderizado inmediato de la tabla de productos
        this.cdr.detectChanges();
      },
      error: () => console.error('Error al listar productos'),
    });
  }

  cargarCategorias(): void {
    this.catService.listar().subscribe({
      next: (res: any) => {
        this.categorias = res.data;
        // 3. Renderizado inmediato del select box de categorías en el formulario
        this.cdr.detectChanges();
      },
      error: () => console.error('Error al cargar categorías'),
    });
  }

  onSubmit(): void {
    if (this.editando) {
      this.prodService.actualizar(this.productoForm.idProducto, this.productoForm).subscribe({
        next: (res: any) => {
          Swal.fire('Actualizado', res.mensaje, 'success');
          this.limpiarForm();
          this.listarProductos(); // El método listarProductos ya tiene su propio detectChanges() interno
        },
        error: () => Swal.fire('Error', 'No se pudo actualizar el platillo', 'error'),
      });
    } else {
      this.prodService.guardar(this.productoForm).subscribe({
        next: (res: any) => {
          Swal.fire('Registrado', res.mensaje, 'success');
          this.limpiarForm();
          this.listarProductos();
        },
        error: () => Swal.fire('Error', 'No se pudo guardar el platillo', 'error'),
      });
    }
  }

  // RF-06: Cambio rápido de Stock usando PatchMapping
  cambiarStock(id: number, stockActual: number): void {
    Swal.fire({
      title: 'Actualizar Stock',
      input: 'number',
      inputValue: stockActual.toString(),
      showCancelButton: true,
      confirmButtonText: 'Actualizar',
      cancelButtonText: 'Cancelar',
    }).then((result) => {
      if (result.isConfirmed && result.value) {
        this.prodService.actualizarStock(id, parseInt(result.value)).subscribe({
          next: (res: any) => {
            Swal.fire('Éxito', res.mensaje, 'success');
            this.listarProductos(); // Refresca y actualiza el badge visual de stock al instante
          },
          error: () => Swal.fire('Error', 'No se pudo actualizar el inventario', 'error'),
        });
      }
    });
  }

  seleccionarEditar(prod: any): void {
    this.productoForm = { ...prod };
    if (!this.productoForm.categoria) {
      this.productoForm.categoria = { idCategoria: null };
    }
    this.editando = true;
    this.cdr.detectChanges(); // Fuerza a que el formulario se llene visualmente de inmediato
  }

  eliminar(id: number): void {
    Swal.fire({
      title: '¿Eliminar producto?',
      text: 'Esta acción no se puede deshacer.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar',
    }).then((result) => {
      if (result.isConfirmed) {
        this.prodService.eliminar(id).subscribe({
          next: (res: any) => {
            Swal.fire('Eliminado', res.mensaje, 'success');
            this.listarProductos(); // Refresca la tabla removiendo el elemento
          },
          error: () => Swal.fire('Error', 'No se pudo eliminar el producto', 'error'),
        });
      }
    });
  }

  limpiarForm(): void {
    this.productoForm = {
      idProducto: null,
      nombre: '',
      descripcion: '',
      precio: 0,
      stock: 0,
      urlImagen: '',
      categoria: { idCategoria: null },
    };
    this.editando = false;
    this.cdr.detectChanges(); // Limpia los inputs en la pantalla al instante
  }
}
