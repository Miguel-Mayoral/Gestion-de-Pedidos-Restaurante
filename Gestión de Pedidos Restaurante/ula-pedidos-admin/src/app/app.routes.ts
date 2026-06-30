import { Routes } from '@angular/router';
import { HomeComp } from './components/home-comp/home-comp';
import { RegistrarComp } from './components/registrar-comp/registrar-comp';
import { authGuard } from './guards/auth-guard';
import { PedidosComp } from './components/pedidos-comp/pedidos-comp';
import { CategoriasComp } from './components/categorias-comp/categorias-comp';
import { ClientesComp } from './components/clientes-comp/clientes-comp';
import { ProductosComp } from './components/productos-comp/productos-comp';
import { DashboardComp } from './components/dashboard-comp/dashboard-comp';

export const routes: Routes = [
  { path: '', redirectTo: 'app/home', pathMatch: 'full' },
  { path: 'app/home', component: HomeComp },
  { path: 'app/registrar', component: RegistrarComp },
  //Ruta exclusiva para el Admin
  { path: 'app/dashboard', component: DashboardComp, canActivate: [authGuard] },

  { path: 'app/pedidos', component: PedidosComp, canActivate: [authGuard] },
  { path: 'app/categorias', component: CategoriasComp, canActivate: [authGuard] },
  { path: 'app/productos', component: ProductosComp, canActivate: [authGuard] },
  { path: 'app/clientes', component: ClientesComp, canActivate: [authGuard] }
];
