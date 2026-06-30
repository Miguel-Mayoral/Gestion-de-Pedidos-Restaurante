import { ChangeDetectorRef, Component, inject, OnInit, PLATFORM_ID } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common'; // <-- Importar utilidades de plataforma
import { FormsModule } from '@angular/forms';
import { CategoriasService } from '../../services/categorias-service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-categorias-comp',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './categorias-comp.html'
})
export class CategoriasComp implements OnInit {
  private platformId = inject(PLATFORM_ID);
  private cdr = inject(ChangeDetectorRef);

  categorias: any[] = [];
  categoriaForm = { idCategoria: null, nombre: '', descripcion: '', estado: 1 };
  editando: boolean = false;

  constructor(private catService: CategoriasService) {
    // El constructor se queda limpio, sin invocar detectChanges() antes de tiempo
  }

  ngOnInit(): void {
    // 1. Evitamos colisiones de renderizado asíncrono con el Servidor (SSR)
    if (isPlatformBrowser(this.platformId)) {
      this.listar();
    }
  }

  listar(): void {
    this.catService.listar().subscribe({
      next: (res: any) => {
        this.categorias = res.data;
        // 2. Obligamos a Angular a pintar la tabla en cuanto responda Spring Boot
        this.cdr.detectChanges();
      },
      error: () => console.error('Error al listar categorías')
    });
  }

  onSubmit(): void {
    if (this.editando && this.categoriaForm.idCategoria) {
      this.catService.actualizar(this.categoriaForm.idCategoria, this.categoriaForm).subscribe({
        next: (res: any) => {
          Swal.fire('Actualizado', res.mensaje, 'success');
          this.limpiarForm();
          this.listar(); // El método listar ya actualiza visualmente la tabla
        },
        error: () => Swal.fire('Error', 'No se pudo actualizar la categoría', 'error')
      });
    } else {
      this.catService.guardar(this.categoriaForm).subscribe({
        next: (res: any) => {
          Swal.fire('Registrado', res.mensaje, 'success');
          this.limpiarForm();
          this.listar();
        },
        error: () => Swal.fire('Error', 'No se pudo registrar la categoría', 'error')
      });
    }
  }

  seleccionarEditar(cat: any): void {
    this.categoriaForm = { ...cat };
    this.editando = true;
    this.cdr.detectChanges(); // Fuerza a que los inputs del formulario se llenen inmediatamente
  }

  eliminar(id: number): void {
    Swal.fire({
      title: '¿Eliminar categoría?',
      text: "Asegúrate de que no tenga productos asociados.",
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then(result => {
      if (result.isConfirmed) {
        this.catService.eliminar(id).subscribe({
          next: (res: any) => {
            Swal.fire('Eliminado', res.mensaje, 'success');
            this.listar(); // Remueve el elemento de la tabla al instante
          },
          error: () => Swal.fire('Error', 'No se pudo eliminar la categoría', 'error')
        });
      }
    });
  }

  limpiarForm(): void {
    this.categoriaForm = { idCategoria: null, nombre: '', descripcion: '', estado: 1 };
    this.editando = false;
    this.cdr.detectChanges(); // Limpia los campos visualmente al momento
  }
}
