import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import { ProjectInfo, SensorReading, User } from '../models';

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly base = environment.apiUrl;

  constructor(private http: HttpClient) {}

  getProjectInfo(): Observable<ProjectInfo> {
    return this.http.get<ProjectInfo>(`${this.base}/public/info`);
  }

  getPricing(): Observable<{ plans: unknown[] }> {
    return this.http.get<{ plans: unknown[] }>(`${this.base}/public/pricing`);
  }

  submitContact(payload: { name: string; email: string; message: string }): Observable<void> {
    return this.http.post<void>(`${this.base}/contact`, payload);
  }

  getRecentSensors(page = 0, size = 50): Observable<{ content: SensorReading[] }> {
    return this.http.get<{ content: SensorReading[] }>(
      `${this.base}/pro/sensors?page=${page}&size=${size}`,
      { withCredentials: true }
    );
  }

  getConnectionStatus(): Observable<{ mqttConnected: boolean }> {
    return this.http.get<{ mqttConnected: boolean }>(`${this.base}/pro/connection`, { withCredentials: true });
  }

  createCheckout(): Observable<{ checkoutUrl: string }> {
    return this.http.post<{ checkoutUrl: string }>(
      `${this.base}/subscription/checkout`, {}, { withCredentials: true });
  }

  completeCheckout(sessionId: string): Observable<User> {
    return this.http.post<User>(
      `${this.base}/subscription/complete?session_id=${encodeURIComponent(sessionId)}`,
      {}, { withCredentials: true });
  }
}
