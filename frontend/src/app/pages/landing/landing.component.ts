import { Component, OnInit } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { ProjectInfo } from '../../core/models';

@Component({
  selector: 'app-landing',
  standalone: true,
  imports: [RouterLink],
  template: `
    <section class="hero page-container">
      <div class="hero-text">
        <h1>{{ info?.name || 'AquaSense' }}</h1>
        <p class="tagline">{{ info?.tagline || 'Smart Irrigation Management Center' }}</p>
        <p class="desc">{{ info?.description }}</p>
        <div class="actions">
          <a routerLink="/register" class="btn-primary">Get Started</a>
          <a routerLink="/pricing" class="btn-secondary">View Pro Plans</a>
        </div>
      </div>
      <div class="hero-cards">
        <div class="card stat">
          <span class="value">24/7</span>
          <span class="label">Remote Monitoring</span>
        </div>
        <div class="card stat">
          <span class="value">IoT</span>
          <span class="label">Sensor Network</span>
        </div>
        <div class="card stat">
          <span class="value">Sync</span>
          <span class="label">Desktop Companion</span>
        </div>
      </div>
    </section>
    @if (info?.features) {
      <section class="page-container features">
        <h2 class="header-title">Why AquaSense?</h2>
        <ul>
          @for (f of info!.features; track f) {
            <li class="card">{{ f }}</li>
          }
        </ul>
      </section>
    }
  `,
  styles: [`
    .hero { display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; align-items: center; padding-top: 3rem; }
    h1 { font-size: 2.75rem; margin: 0; color: #1B5E20; }
    .tagline { font-size: 1.25rem; color: #43A047; font-weight: 600; }
    .desc { color: #616161; line-height: 1.6; }
    .actions { display: flex; gap: 1rem; margin-top: 1.5rem; }
    .actions a { text-decoration: none; display: inline-block; text-align: center; }
    .hero-cards { display: flex; flex-direction: column; gap: 1rem; }
    .stat { text-align: center; }
    .value { display: block; font-size: 2rem; font-weight: 700; color: #1B5E20; }
    .label { color: #616161; font-size: 0.9rem; }
    .features ul { list-style: none; padding: 0; display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1rem; }
    .features li { margin: 0; }
    @media (max-width: 768px) { .hero { grid-template-columns: 1fr; } }
  `]
})
export class LandingComponent implements OnInit {
  info: ProjectInfo | null = null;

  constructor(private api: ApiService) {}

  ngOnInit(): void {
    this.api.getProjectInfo().subscribe(info => this.info = info);
  }
}
