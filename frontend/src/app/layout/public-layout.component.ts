import { Component, OnInit } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { AuthService } from '../core/services/auth.service';

@Component({
  selector: 'app-public-layout',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <header class="nav">
      <a routerLink="/" class="brand">AquaSense</a>
      <nav>
        <a routerLink="/" routerLinkActive="active" [routerLinkActiveOptions]="{ exact: true }">Home</a>
        <a routerLink="/about" routerLinkActive="active">About</a>
        <a routerLink="/pricing" routerLinkActive="active">Pricing</a>
        <a routerLink="/contact" routerLinkActive="active">Contact</a>
        @if (auth.user()) {
          @if (auth.isPro()) {
            <a routerLink="/charts" routerLinkActive="active" class="charts-link">📊 Charts</a>
            <span class="pro-badge">Pro</span>
          } @else {
            <a routerLink="/pricing" class="upgrade-link">Upgrade to Pro</a>
          }
          <button class="btn-link" (click)="auth.logout()">Logout</button>
        } @else {
          <a routerLink="/login" routerLinkActive="active">Login</a>
          <a routerLink="/register" class="btn-nav" routerLinkActive="active">Sign up</a>
        }
      </nav>
    </header>
    <main><router-outlet /></main>
    <footer class="footer">
      <p>AquaSense — Smart Irrigation Management Center</p>
      <p class="muted">Syncs with the JavaFX desktop companion app in real time.</p>
    </footer>
  `,
  styles: [`
    .nav {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 1rem 2rem;
      background: rgba(255,255,255,0.98);
      box-shadow: 0 3px 12px rgba(0,0,0,0.08);
    }
    .brand {
      font-size: 1.4rem;
      font-weight: 700;
      color: #1B5E20;
      text-decoration: none;
    }
    nav {
      display: flex;
      gap: 1.25rem;
      align-items: center;
    }
    nav a {
      color: #616161;
      font-weight: 500;
      text-decoration: none;
    }
    nav a.active, nav a:hover { color: #43A047; }
    .charts-link { font-weight: 600; color: #2E7D32 !important; }
    .pro-badge {
      background: #e8f5e9;
      color: #2E7D32;
      font-size: 0.75rem;
      font-weight: 700;
      padding: 0.2rem 0.55rem;
      border-radius: 6px;
    }
    .upgrade-link {
      color: #43A047 !important;
      font-weight: 600;
    }
    .btn-nav {
      background: linear-gradient(to bottom right, #66BB6A, #43A047);
      color: white !important;
      padding: 0.5rem 1rem;
      border-radius: 8px;
    }
    main { min-height: calc(100vh - 140px); }
    .footer {
      text-align: center;
      padding: 1.5rem;
      color: #616161;
      font-size: 0.875rem;
    }
    .muted { opacity: 0.8; }
  `]
})
export class PublicLayoutComponent implements OnInit {
  constructor(public auth: AuthService) {}

  ngOnInit(): void {
    this.auth.restoreSession().subscribe();
  }
}
