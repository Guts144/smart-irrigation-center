import { Component } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [ReactiveFormsModule, RouterLink],
  template: `
    <div class="page-container auth-page">
      <div class="card auth-card">
        <h1 class="header-title">Create account</h1>
        @if (error) { <div class="error-banner">{{ error }}</div> }
        @if (success) { <div class="success">Account created! <a routerLink="/login">Sign in</a></div> }
        <form [formGroup]="form" (ngSubmit)="submit()">
          <div class="form-field">
            <label>Full name</label>
            <input formControlName="fullName" />
          </div>
          <div class="form-field">
            <label>Email</label>
            <input type="email" formControlName="email" />
          </div>
          <div class="form-field">
            <label>Password</label>
            <input type="password" formControlName="password" />
          </div>
          <button class="btn-primary" type="submit" [disabled]="form.invalid || loading">Register</button>
        </form>
        <p class="footer-link">Already have an account? <a routerLink="/login">Sign in</a></p>
      </div>
    </div>
  `,
  styles: [`
    .auth-page { display: flex; justify-content: center; padding-top: 3rem; }
    .auth-card { width: 100%; max-width: 420px; }
    button { width: 100%; }
    .footer-link { text-align: center; margin-top: 1.5rem; color: #616161; }
    .success { background: #e8f5e9; color: #2E7D32; padding: 0.75rem; border-radius: 8px; margin-bottom: 1rem; }
  `]
})
export class RegisterComponent {
  loading = false;
  error = '';
  success = false;
  form = this.fb.group({
    fullName: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  constructor(private fb: FormBuilder, private auth: AuthService, private router: Router) {}

  submit(): void {
    if (this.form.invalid) return;
    this.loading = true;
    this.error = '';
    this.auth.register(this.form.getRawValue() as { fullName: string; email: string; password: string }).subscribe({
      next: () => { this.success = true; this.loading = false; },
      error: err => {
        this.error = err.error?.detail || 'Registration failed';
        this.loading = false;
      },
    });
  }
}
