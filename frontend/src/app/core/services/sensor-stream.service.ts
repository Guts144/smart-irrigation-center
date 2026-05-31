import { Injectable, signal } from '@angular/core';
import { Client, IMessage } from '@stomp/stompjs';
import { Subject } from 'rxjs';
import { environment } from '../../../environments/environment';
import { SensorReading } from '../models';

@Injectable({ providedIn: 'root' })
export class SensorStreamService {
  readonly latestReading = signal<SensorReading | null>(null);
  readonly connected = signal(false);
  readonly onReading$ = new Subject<SensorReading>();

  private client: Client | null = null;

  connect(): void {
    if (this.client?.active) return;

    const path = environment.wsUrl.startsWith('/') ? environment.wsUrl : `/${environment.wsUrl}`;
    const url = `${window.location.protocol}//${window.location.host}${path}`;

    void import('sockjs-client').then(({ default: SockJS }) => {
      this.client = new Client({
        webSocketFactory: () => new SockJS(url) as WebSocket,
        reconnectDelay: 5000,
        onConnect: () => {
          this.connected.set(true);
          this.client!.subscribe('/topic/sensors', (msg: IMessage) => {
            const reading = JSON.parse(msg.body) as SensorReading;
            this.latestReading.set(reading);
            this.onReading$.next(reading);
          });
        },
        onDisconnect: () => this.connected.set(false),
        onStompError: () => this.connected.set(false),
        onWebSocketClose: () => this.connected.set(false),
      });

      this.client.activate();
    });
  }

  disconnect(): void {
    this.client?.deactivate();
    this.client = null;
    this.connected.set(false);
  }
}
