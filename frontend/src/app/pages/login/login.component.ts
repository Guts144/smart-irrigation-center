import { Component } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
    <div class="page-container auth-page">
      <div class="card auth-card">
        <h1 class="header-title">Sign in</h1>
        <p class="sub">Access your irrigation management center</p>
        @if (error) { <div class="error-banner">{{ error }}</div> }
        <form [formGroup]="form" (ngSubmit)="submit()">
          <div class="form-field">
            <label>Email</label>
            <input type="email" formControlName="email" placeholder="you@farm.com" />
          </div>
          <div class="form-field">
            <label>Password</label>
            <input type="password" formControlName="password" />
          </div>
          <button class="btn-primary" type="submit" [disabled]="form.invalid || loading">
            {{ loading ? 'Signing in…' : 'Sign in' }}
          </button>
        </form>
        <p class="footer-link">No account? <a routerLink="/register">Create one</a></p>
      </div>
    </div>
  `,
  styles: [`
    .auth-page { display: flex; justify-content: center; padding-top: 3rem; }
    .auth-card { width: 100%; max-width: 420px; }
    .sub { color: #616161; margin-bottom: 1.5rem; }
    button { width: 100%; margin-top: 0.5rem; }
    .footer-link { text-align: center; margin-top: 1.5rem; color: #616161; }
  `]
})
export class LoginComponent {
  loading = false;
  error = '';
  form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required],
  });

  constructor(private fb: FormBuilder, private auth: AuthService, private router: Router) {}

  submit(): void {
    if (this.form.invalid) return;
    this.loading = true;
    this.error = '';
    this.auth.login(this.form.getRawValue() as { email: string; password: string }).subscribe({
      next: user => {
        this.router.navigate([user.pro || user.role === 'ADMIN' ? '/charts' : '/']);
      },
      error: err => {
        this.error = err.error?.detail || 'Invalid credentials';
        this.loading = false;
      },
      complete: () => this.loading = false,
    });
  }
}
