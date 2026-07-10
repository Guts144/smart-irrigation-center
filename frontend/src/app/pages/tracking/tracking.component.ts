import { Component, OnDestroy, OnInit, Inject, PLATFORM_ID, NgZone } from '@angular/core';
import { isPlatformBrowser, CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { catchError, map } from 'rxjs/operators';
import { of } from 'rxjs';
import { Client, Message } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import * as L from 'leaflet';

interface TrackingInfo {
  sessionId: number;
  technicianName: string;
  status: string;
  currentLatitude: number;
  currentLongitude: number;
  destinationLatitude: number;
  destinationLongitude: number;
  currentSpeed: number;
  lastUpdate: string;
  estimatedArrival: string;
  distanceRemaining: number;
}

@Component({
  selector: 'app-tracking',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="tracking-container">
      <div class="header">
        <h2>Live Team Tracking</h2>
        
        @if (trackingInfo) {
          <div class="badges">
            <span class="badge" [class.success]="stompClient?.connected" [class.danger]="!stompClient?.connected">
              {{ stompClient?.connected ? 'Live' : 'Disconnected' }}
            </span>
            <span class="badge" [class.info]="trackingInfo.status === 'ACTIVE'" [class.success]="trackingInfo.status === 'ARRIVED'">
              {{ trackingInfo.status | titlecase }}
            </span>
          </div>
        }
      </div>

      <!-- No active tracking session -->
      @if (!trackingInfo && !loading) {
        <div class="no-session">
          <p>No active tracking session found.</p>
          <small>Once our team is dispatched, you can track them here in real time.</small>
        </div>
      }

      <!-- Arrived specific message -->
      @if (trackingInfo?.status === 'ARRIVED') {
        <div class="success-banner">
          <h3>✅ Our team has arrived!</h3>
          <p>Thank you for choosing Smart Irrigation. The technician is now at your location.</p>
        </div>
      }

      @if (trackingInfo) {
        <div class="info-grid">
          <div class="info-card">
            <h4>Technician</h4>
            <p>{{ trackingInfo.technicianName }}</p>
          </div>
          <div class="info-card">
             <h4>Last Update</h4>
             <p>{{ trackingInfo.lastUpdate | date:'mediumTime' }}</p>
          </div>
          <div class="info-card">
             <h4>Distance</h4>
             <p>{{ trackingInfo.distanceRemaining ? (trackingInfo.distanceRemaining / 1000 | number:'1.1-2') + ' km' : '--' }}</p>
          </div>
          <div class="info-card">
             <h4>Estimated Arrival</h4>
             <p>{{ trackingInfo.estimatedArrival ? (trackingInfo.estimatedArrival | date:'shortTime') : '--' }}</p>
          </div>
        </div>

        <div class="map-wrapper" [class.disabled]="trackingInfo.status === 'ARRIVED'">
          <div id="map"></div>
        </div>
      }
    </div>
  `,
  styles: [`
    .tracking-container {
      padding: 1.5rem;
      max-width: 1200px;
      margin: 0 auto;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
    }
    .header h2 {
      margin: 0;
      color: #2E7D32;
      font-size: 1.75rem;
    }
    .badges {
      display: flex;
      gap: 0.5rem;
    }
    .badge {
      padding: 0.35rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.85rem;
      font-weight: 600;
      color: white;
    }
    .badge.success { background-color: #2E7D32; }
    .badge.danger { background-color: #d32f2f; }
    .badge.info { background-color: #1976d2; }

    .no-session {
      background: white;
      padding: 2.5rem;
      border-radius: 12px;
      text-align: center;
      box-shadow: 0 4px 6px rgba(0,0,0,0.05);
    }
    .no-session p { font-size: 1.25rem; font-weight: 500; margin-bottom: 0.5rem; }
    .no-session small { color: #666; }

    .success-banner {
      background: #e8f5e9;
      border: 1px solid #c8e6c9;
      color: #2e7d32;
      padding: 1rem 1.5rem;
      border-radius: 8px;
      margin-bottom: 1.5rem;
    }
    .success-banner h3 { margin: 0 0 0.5rem; font-size: 1.25rem; }
    .success-banner p { margin: 0; font-size: 0.95rem; }

    .info-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
      margin-bottom: 1.5rem;
    }
    .info-card {
      background: white;
      padding: 1rem 1.5rem;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
      border-left: 4px solid #4caf50;
    }
    .info-card h4 {
      margin: 0 0 0.25rem;
      color: #666;
      font-size: 0.85rem;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .info-card p {
      margin: 0;
      font-size: 1.15rem;
      font-weight: 600;
      color: #333;
    }

    .map-wrapper {
      background: white;
      border-radius: 12px;
      padding: 0.5rem;
      box-shadow: 0 4px 6px rgba(0,0,0,0.05);
      height: 500px;
    }
    .map-wrapper.disabled {
      opacity: 0.8;
      pointer-events: none;
    }
    #map {
      width: 100%;
      height: 100%;
      border-radius: 8px;
      z-index: 1; /* allow dropdowns on top */
    }
    
    ::ng-deep .dest-marker,
    ::ng-deep .vehicle-marker {
      font-size: 30px;
      line-height: 30px;
      text-align: center;
      background: transparent;
      border: none;
    }
  `]
})
export class TrackingComponent implements OnInit, OnDestroy {
  trackingInfo: TrackingInfo | null = null;
  loading = true;
  stompClient: Client | null = null;

  private map: L.Map | null = null;
  private techMarker: L.Marker | null = null;
  private destMarker: L.Marker | null = null;
  private routeLine: L.Polyline | null = null;
  private routePoints: [number, number][] = [];
  private isBrowser: boolean;

  constructor(
    private http: HttpClient,
    private zone: NgZone,
    @Inject(PLATFORM_ID) platformId: object
  ) {
    this.isBrowser = isPlatformBrowser(platformId);
  }

  ngOnInit(): void {
    this.http.get<TrackingInfo>(`${environment.apiUrl}/tracking/active`).pipe(
      catchError(() => of(null))
    ).subscribe(info => {
      if (info) {
        this.enhanceTrackingInfoWithDefaults(info);
      }
      this.trackingInfo = info;
      this.loading = false;
      if (info && this.isBrowser) {
        setTimeout(() => this.initMap(), 100);
        if (info.status === 'ACTIVE') {
          this.connectWebSocket(info.sessionId);
        }
      }
    });
  }

  ngOnDestroy(): void {
    if (this.stompClient) {
      this.stompClient.deactivate();
    }
    if (this.map) {
      this.map.remove();
    }
  }

  private initMap(): void {
    if (!this.trackingInfo) return;

    const lat = this.trackingInfo.currentLatitude || this.trackingInfo.destinationLatitude;
    const lng = this.trackingInfo.currentLongitude || this.trackingInfo.destinationLongitude;

    this.map = L.map('map').setView([lat, lng], 13);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap contributors'
    }).addTo(this.map);

    if (this.trackingInfo.currentLatitude && this.trackingInfo.currentLongitude) {
      this.routePoints.push([this.trackingInfo.currentLatitude, this.trackingInfo.currentLongitude]);
      const carIcon = L.divIcon({
        html: '🚐',
        className: 'vehicle-marker',
        iconSize: [30, 30],
        iconAnchor: [15, 15]
      });
      this.techMarker = L.marker([this.trackingInfo.currentLatitude, this.trackingInfo.currentLongitude], { icon: carIcon })
        .addTo(this.map)
        .bindPopup('Technician');
    }

    if (this.trackingInfo.destinationLatitude && this.trackingInfo.destinationLongitude) {
      const destIcon = L.divIcon({
        html: '📍',
        className: 'dest-marker',
        iconSize: [30, 30],
        iconAnchor: [15, 30]
      });
      this.destMarker = L.marker([this.trackingInfo.destinationLatitude, this.trackingInfo.destinationLongitude], { icon: destIcon })
        .addTo(this.map)
        .bindPopup('Destination');
    }

    this.routeLine = L.polyline(this.routePoints, { color: '#42a5f5', weight: 4 }).addTo(this.map);

    this.fitBounds();
  }

  private fitBounds(): void {
    if (!this.map) return;

    const bounds = L.latLngBounds([]);
    if (this.techMarker) bounds.extend(this.techMarker.getLatLng());
    if (this.destMarker) bounds.extend(this.destMarker.getLatLng());

    if (bounds.isValid()) {
      this.map.fitBounds(bounds, { padding: [50, 50], maxZoom: 16 });
    }
  }

  private connectWebSocket(sessionId: number): void {
    if (!this.isBrowser) return;

    // the port issue or domain issue: 
    const wsUrl = environment.apiUrl.includes('localhost')
      ? environment.apiUrl.replace('http://', 'ws://').replace('/api', '') + '/ws'
      : environment.apiUrl.replace('https://', 'wss://').replace('/api', '') + '/ws';

    // Better safely fallback to sockjs directly using URL rather than wss:
    const finalUrl = environment.apiUrl.replace('/api', '') + '/ws';

    this.stompClient = new Client({
      webSocketFactory: () => new SockJS(finalUrl),
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000
    });

    this.stompClient.onConnect = () => {
      this.stompClient?.subscribe(`/topic/tracking/${sessionId}`, (message: Message) => {
        this.zone.run(() => {
          this.handleTrackingUpdate(JSON.parse(message.body));
        });
      });
    };

    this.stompClient.activate();
  }

  private handleTrackingUpdate(info: TrackingInfo): void {
    this.enhanceTrackingInfoWithDefaults(info);
    this.trackingInfo = info;

    if (info.status === 'ARRIVED') {
      if (this.stompClient) {
        this.stompClient.deactivate();
      }
    }

    if (this.map && info.currentLatitude && info.currentLongitude) {
      const newPos: [number, number] = [info.currentLatitude, info.currentLongitude];

      if (this.techMarker) {
        this.techMarker.setLatLng(newPos);
      } else {
        const carIcon = L.divIcon({ html: '🚐', className: 'vehicle-marker', iconSize: [30, 30], iconAnchor: [15, 15] });
        this.techMarker = L.marker(newPos, { icon: carIcon }).addTo(this.map).bindPopup('Technician');
      }

      this.routePoints.push(newPos);
      if (this.routeLine) {
        this.routeLine.setLatLngs(this.routePoints);
      }
      this.fitBounds();
    }
  }

  private enhanceTrackingInfoWithDefaults(info: TrackingInfo): void {
    // Fallback to testing destination if none provided by backend
    info.destinationLatitude = info.destinationLatitude || 36.806496;
    info.destinationLongitude = info.destinationLongitude || 10.181532;

    if (info.currentLatitude && info.currentLongitude) {
      // Haversine formula to compute distance in meters
      const R = 6371e3; // Radius in meters
      const lat1 = info.currentLatitude * Math.PI / 180;
      const lat2 = info.destinationLatitude * Math.PI / 180;
      const dLat = (info.destinationLatitude - info.currentLatitude) * Math.PI / 180;
      const dLon = (info.destinationLongitude - info.currentLongitude) * Math.PI / 180;

      const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1) * Math.cos(lat2) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      const distance = R * c;

      info.distanceRemaining = distance;

      // Calculate ETA
      // If speed is 0 (likely when testing at a desk), assume 50km/h = 13.88 m/s
      const speed = (info.currentSpeed && info.currentSpeed > 0) ? info.currentSpeed : 13.88;

      const etaSeconds = distance / speed;
      const eta = new Date();
      eta.setSeconds(eta.getSeconds() + etaSeconds);
      info.estimatedArrival = eta.toISOString();
    }
  }
}
