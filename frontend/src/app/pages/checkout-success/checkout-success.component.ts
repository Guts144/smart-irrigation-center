import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-checkout-success',
  standalone: true,
  template: `
    <div class="page-container">
      <div class="card">
        <h1 class="header-title">Confirming payment…</h1>
        <p>Please wait while we activate your Pro subscription.</p>
        @if (error) {
          <div class="error-banner">{{ error }}</div>
          <button class="btn-link" (click)="router.navigate(['/pricing'])">Back to pricing</button>
        }
      </div>
    </div>
  `,
  styles: [`
    .page-container { display: flex; justify-content: center; padding-top: 4rem; }
    .card { max-width: 480px; text-align: center; }
    p { color: #616161; }
  `]
})
export class CheckoutSuccessComponent implements OnInit {
  error = '';

  constructor(
    private route: ActivatedRoute,
    public router: Router,
    private api: ApiService,
    private auth: AuthService,
  ) {}

  ngOnInit(): void {
    const sessionId = this.route.snapshot.queryParamMap.get('session_id');
    if (!sessionId) {
      this.router.navigate(['/pricing']);
      return;
    }
    this.api.completeCheckout(sessionId).subscribe({
      next: user => {
        this.auth.user.set(user);
        this.router.navigate(['/pro/charts']);
      },
      error: err => {
        this.error = err.error?.detail || 'Could not verify payment. Contact support if you were charged.';
      },
    });
  }
}
