import { Component } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ApiService } from '../../core/services/api.service';

@Component({
  selector: 'app-contact',
  standalone: true,
  imports: [ReactiveFormsModule],
  template: `
    <div class="page-container">
      <h1 class="header-title">Contact us</h1>
      <p class="sub">Questions about AquaSense or enterprise deployments?</p>
      <div class="card form-card">
        @if (sent) { <div class="success">Message sent. We'll get back to you soon.</div> }
        @if (error) { <div class="error-banner">{{ error }}</div> }
        <form [formGroup]="form" (ngSubmit)="submit()">
          <div class="form-field"><label>Name</label><input formControlName="name" /></div>
          <div class="form-field"><label>Email</label><input type="email" formControlName="email" /></div>
          <div class="form-field"><label>Message</label><textarea rows="5" formControlName="message"></textarea></div>
          <button class="btn-primary" type="submit" [disabled]="form.invalid || loading">Send message</button>
        </form>
      </div>
    </div>
  `,
  styles: [`
    .sub { color: #616161; margin-bottom: 1.5rem; }
    .form-card { max-width: 560px; }
    .success { background: #e8f5e9; color: #2E7D32; padding: 0.75rem; border-radius: 8px; margin-bottom: 1rem; }
  `]
})
export class ContactComponent {
  loading = false;
  sent = false;
  error = '';
  form = this.fb.group({
    name: ['', Validators.required],
    email: ['', [Validators.required, Validators.email]],
    message: ['', Validators.required],
  });

  constructor(private fb: FormBuilder, private api: ApiService) {}

  submit(): void {
    if (this.form.invalid) return;
    this.loading = true;
    this.api.submitContact(this.form.getRawValue() as { name: string; email: string; message: string }).subscribe({
      next: () => { this.sent = true; this.form.reset(); this.loading = false; },
      error: err => {
        this.error = err.error?.detail || 'Failed to send message. Please try again.';
        this.loading = false;
      },
    });
  }
}
