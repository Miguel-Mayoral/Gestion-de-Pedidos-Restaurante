import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';
import { ClientesService } from '../../services/clientes-service';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-home-comp',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './home-comp.html',
})
export class HomeComp implements OnInit {
  correoLogin: string = '';

  constructor(
    private clientesService: ClientesService,
    private router: Router,
  ) {}

  ngOnInit(): void {
    if (this.clientesService.isLoggedIn()) {
      this.router.navigate(['/app/dashboard']);
    }
  }

  onLogin(): void {
    if (!this.correoLogin) return;

    this.clientesService.listarClientes().subscribe({
      next: (res: any) => {
        const listaClientes = res.data;
        // Buscamos si existe el correo ingresado en la base de datos
        const usuarioEncontrado = listaClientes.find((c: any) => c.correo === this.correoLogin);

        if (usuarioEncontrado) {
          this.clientesService.setSession(usuarioEncontrado);
          Swal.fire('¡Bienvenido!', `Hola de nuevo, ${usuarioEncontrado.nombre}`, 'success');
          this.router.navigate(['/app/dashboard']);
        } else {
          Swal.fire('Error', 'El correo electrónico no se encuentra registrado.', 'error');
        }
      },
      error: () => Swal.fire('Error', 'No se pudo conectar con el servidor', 'error'),
    });
  }
}

