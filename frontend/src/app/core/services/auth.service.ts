import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, catchError, of, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { User } from '../models';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly base = `${environment.apiUrl}/auth`;
  readonly user = signal<User | null>(null);

  constructor(private http: HttpClient, private router: Router) {}

  register(payload: { fullName: string; email: string; password: string }): Observable<User> {
    return this.http.post<User>(`${this.base}/register`, payload, { withCredentials: true });
  }

  login(payload: { email: string; password: string }): Observable<User> {
    return this.http.post<User>(`${this.base}/login`, payload, { withCredentials: true }).pipe(
      tap(user => this.user.set(user))
    );
  }

  refresh(): Observable<User> {
    return this.http.post<User>(`${this.base}/refresh`, {}, { withCredentials: true }).pipe(
      tap(user => this.user.set(user))
    );
  }

  /** Always loads latest subscription status from the server. */
  me(): Observable<User> {
    return this.http.get<User>(`${this.base}/me`, { withCredentials: true }).pipe(
      tap(user => this.user.set(user))
    );
  }

  /** Restore session on app load (cookies may exist from a prior visit). */
  restoreSession(): Observable<User | null> {
    return this.me().pipe(catchError(() => {
      this.user.set(null);
      return of(null);
    }));
  }

  logout(): void {
    this.http.post(`${this.base}/logout`, {}, { withCredentials: true }).subscribe({
      complete: () => {
        this.user.set(null);
        this.router.navigate(['/']);
      }
    });
  }

  isAuthenticated(): boolean {
    return this.user() !== null;
  }

  isPro(): boolean {
    const u = this.user();
    return !!u && (u.pro || u.role === 'ADMIN');
  }

  isSubscribed(): boolean {
    const u = this.user();
    return !!u && u.subscriptionStatus === 'ACTIVE';
  }
}
