import { Routes } from '@angular/router';
import { PublicLayoutComponent } from './layout/public-layout.component';
import { authGuard, proGuard, guestGuard } from './core/guards/auth.guards';

export const routes: Routes = [
  {
    path: '',
    component: PublicLayoutComponent,
    children: [
      { path: '', loadComponent: () => import('./pages/landing/landing.component').then(m => m.LandingComponent) },
      { path: 'about', loadComponent: () => import('./pages/about/about.component').then(m => m.AboutComponent) },
      { path: 'contact', loadComponent: () => import('./pages/contact/contact.component').then(m => m.ContactComponent) },
      { path: 'pricing', loadComponent: () => import('./pages/pricing/pricing.component').then(m => m.PricingComponent) },
      { path: 'login', canActivate: [guestGuard], loadComponent: () => import('./pages/login/login.component').then(m => m.LoginComponent) },
      { path: 'register', canActivate: [guestGuard], loadComponent: () => import('./pages/register/register.component').then(m => m.RegisterComponent) },
      { path: 'checkout/success', canActivate: [authGuard], loadComponent: () => import('./pages/checkout-success/checkout-success.component').then(m => m.CheckoutSuccessComponent) },
    ],
  },
  {
    path: 'pro',
    canActivate: [authGuard, proGuard],
    loadComponent: () => import('./layout/pro-layout.component').then(m => m.ProLayoutComponent),
    children: [
      { path: 'charts', loadComponent: () => import('./pages/charts/charts.component').then(m => m.ChartsComponent) },
      { path: 'tracking', loadComponent: () => import('./pages/tracking/tracking.component').then(m => m.TrackingComponent) },
      { path: '', redirectTo: 'charts', pathMatch: 'full' }
    ]
  },
  { path: 'charts', redirectTo: '/pro/charts' },
  { path: '**', redirectTo: '' }
];
