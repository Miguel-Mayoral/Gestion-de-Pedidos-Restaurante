import { Component, signal } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { CommandModule } from '@angular/cli/src/command-builder/command-module';
import { CommonModule } from '@angular/common';
import { ClientesService } from './services/clientes-service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet,
  RouterLink,
  RouterLinkActive,
  CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('ula-pedidos-admin');

  //Hacemos el servicio publico para que la plantilla HTML pueda acceder a el directamente
  constructor(
    public authService: ClientesService,
    private router: Router,
  ) {}

  onLogout(): void {
    this.authService.logout();
    this.router.navigate(['/app/home']);
  }
}
