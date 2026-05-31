import { Component, OnInit } from '@angular/core';
import { ApiService } from '../../core/services/api.service';
import { ProjectInfo } from '../../core/models';

@Component({
  selector: 'app-about',
  standalone: true,
  template: `
    <div class="page-container">
      <h1 class="header-title">About AquaSense</h1>
      @if (info) {
        <div class="card">
          <p>{{ info.description }}</p>
          <h3>Desktop companion</h3>
          <p>
            <strong>{{ info.desktopApp.name }}</strong> ({{ info.desktopApp.platform }}) —
            {{ info.desktopApp.sync }}
          </p>
          <h3>Architecture</h3>
          <ul>
            <li>Edge: ESP32 multi-sensor array</li>
            <li>Broker: HiveMQ Cloud (MQTT)</li>
            <li>Web: Spring Boot + Angular with PostgreSQL</li>
            <li>Desktop: JavaFX dashboard with SQLite</li>
          </ul>
        </div>
      }
    </div>
  `,
  styles: [`ul { line-height: 1.8; color: #616161; } h3 { color: #2E7D32; }`]
})
export class AboutComponent implements OnInit {
  info: ProjectInfo | null = null;

  constructor(private api: ApiService) {}

  ngOnInit(): void {
    this.api.getProjectInfo().subscribe(info => this.info = info);
  }
}
