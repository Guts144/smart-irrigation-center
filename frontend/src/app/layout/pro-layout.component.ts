import { Component, OnDestroy, OnInit } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { interval, Subscription } from 'rxjs';
import { AuthService } from '../core/services/auth.service';
import { ApiService } from '../core/services/api.service';

@Component({
  selector: 'app-pro-layout',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, RouterOutlet],
  template: `
    <div class="shell">
      <aside class="sidebar">
        <h2 class="sidebar-title">🌿 Smart Irrigation</h2>
        <hr class="separator" />

        <a routerLink="/" class="sidebar-link">🏠 Home</a>
        <a routerLink="/pro/charts" routerLinkActive="active" class="sidebar-link">📊 Charts</a>
        <a routerLink="/pro/tracking" routerLinkActive="active" class="sidebar-link">📍 Track Our Team</a>

        <div class="spacer"></div>

        <p [class]="mqttConnected ? 'status-connected' : 'status-disconnected'">
          {{ mqttConnected ? '● MQTT Connected' : '● MQTT Disconnected' }}
        </p>
        @if (auth.user(); as user) {
          <p class="user-label">{{ user.fullName || user.email }}</p>
        }
        <button class="btn-danger sidebar-logout" (click)="auth.logout()">Logout</button>
      </aside>

      <main class="content">
        <router-outlet />
      </main>
    </div>
  `,
  styles: [`
    .shell {
      display: flex;
      min-height: 100vh;
    }

    .sidebar {
      width: 220px;
      flex-shrink: 0;
      display: flex;
      flex-direction: column;
      padding: 1.25rem;
      background: linear-gradient(to bottom, #1B5E20 0%, #2E7D32 100%);
      box-shadow: 3px 0 15px rgba(0, 0, 0, 0.3);
    }

    .sidebar-title {
      margin: 0 0 0.5rem;
      color: white;
      font-size: 1.35rem;
      font-weight: 700;
      letter-spacing: 0.5px;
      text-shadow: 0 2px 3px rgba(0, 0, 0, 0.3);
    }

    .separator {
      border: none;
      border-top: 1px solid rgba(255, 255, 255, 0.3);
      margin: 0.75rem 0 1rem;
    }

    .sidebar-link {
      display: block;
      padding: 0.85rem 1.1rem;
      margin-bottom: 0.35rem;
      border-radius: 8px;
      color: rgba(255, 255, 255, 0.9);
      font-size: 1rem;
      font-weight: 500;
      text-decoration: none;
      transition: background 0.15s;
    }

    .sidebar-link:hover,
    .sidebar-link.active {
      background: rgba(255, 255, 255, 0.15);
      color: white;
    }

    .spacer { flex: 1; }

    .status-connected {
      margin: 0 0 0.35rem;
      color: #43A047;
      font-weight: 700;
      font-size: 0.875rem;
    }

    .status-disconnected {
      margin: 0 0 0.35rem;
      color: #e53935;
      font-weight: 700;
      font-size: 0.875rem;
    }

    .user-label {
      margin: 0 0 0.75rem;
      color: #ccc;
      font-size: 0.8rem;
      word-break: break-word;
    }

    .sidebar-logout {
      width: 100%;
      border: none;
      cursor: pointer;
      font-size: 0.95rem;
    }

    .content {
      flex: 1;
      background: #f4f9f4;
      overflow: auto;
    }
  `]
})
export class ProLayoutComponent implements OnInit, OnDestroy {
  mqttConnected = false;
  private pollSub?: Subscription;

  constructor(public auth: AuthService, private api: ApiService) { }

  ngOnInit(): void {
    this.auth.restoreSession().subscribe(() => this.refreshConnection());
    this.pollSub = interval(15000).subscribe(() => this.refreshConnection());
  }

  ngOnDestroy(): void {
    this.pollSub?.unsubscribe();
  }

  private refreshConnection(): void {
    this.api.getConnectionStatus().subscribe({
      next: s => this.mqttConnected = s.mqttConnected,
      error: () => this.mqttConnected = false,
    });
  }
}
