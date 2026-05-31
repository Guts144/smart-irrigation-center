import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { ApiService } from '../../core/services/api.service';
import { AuthService } from '../../core/services/auth.service';
import { PricingPlan } from '../../core/models';

@Component({
  selector: 'app-pricing',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="page-container">
      <h1 class="header-title">Choose your plan</h1>
      @if (error) { <div class="error-banner">{{ error }}</div> }
      @if (cancelled) { <div class="info-banner">Checkout was cancelled. You can try again anytime.</div> }
      @if (subscribed) { <div class="success-banner">Your Pro subscription is now active.</div> }
      <div class="plans">
        @for (plan of plans; track plan.id) {
          <div class="card plan" [class.pro]="plan.id === 'pro'">
            <h2>{{ plan.name }}</h2>
            <p class="price">
              @if (plan.price === 0) { Free }
              @else { \${{ plan.price }}<span>/{{ plan.interval }}</span> }
            </p>
            <ul>
              @for (f of plan.features; track f) { <li>{{ f }}</li> }
            </ul>
            @if (plan.id === 'pro') {
              @if (auth.isPro()) {
                <span class="badge">Active</span>
                <a routerLink="/charts" class="btn-primary link-btn">Open charts</a>
              } @else if (loggedIn) {
                <button class="btn-primary" (click)="checkout()" [disabled]="loading">
                  {{ loading ? 'Processing…' : 'Upgrade to Pro' }}
                </button>
              } @else {
                <a routerLink="/login" class="btn-primary link-btn">Sign in to upgrade</a>
              }
            } @else {
              <a routerLink="/register" class="btn-link">Get started free</a>
            }
          </div>
        }
      </div>
    </div>
  `,
  styles: [`
    .plans { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin-top: 2rem; }
    .plan.pro { border: 2px solid #66BB6A; }
    .price { font-size: 2rem; font-weight: 700; color: #1B5E20; }
    .price span { font-size: 1rem; font-weight: 400; color: #616161; }
    ul { padding-left: 1.2rem; color: #616161; line-height: 1.8; }
    .link-btn { display: inline-block; text-decoration: none; text-align: center; margin-top: 0.5rem; }
    .badge { background: #e8f5e9; color: #2E7D32; padding: 0.5rem 1rem; border-radius: 8px; font-weight: 600; display: inline-block; }
    .info-banner { background: #e3f2fd; color: #1565c0; padding: 0.75rem 1rem; border-radius: 8px; margin-bottom: 1rem; }
    .success-banner { background: #e8f5e9; color: #2E7D32; padding: 0.75rem 1rem; border-radius: 8px; margin-bottom: 1rem; }
  `]
})
export class PricingComponent implements OnInit {
  plans: PricingPlan[] = [];
  loading = false;
  error = '';
  loggedIn = false;
  cancelled = false;
  subscribed = false;

  constructor(public auth: AuthService, private api: ApiService, private route: ActivatedRoute) {}

  ngOnInit(): void {
    this.cancelled = this.route.snapshot.queryParamMap.get('checkout') === 'cancelled';
    this.subscribed = this.route.snapshot.queryParamMap.get('subscribed') === 'true';
    this.api.getPricing().subscribe(p => this.plans = p.plans as PricingPlan[]);
    this.auth.me().subscribe({
      next: () => this.loggedIn = true,
      error: () => this.loggedIn = false,
    });
  }

  checkout(): void {
    this.loading = true;
    this.error = '';
    this.api.createCheckout().subscribe({
      next: res => {
        window.location.href = res.checkoutUrl;
      },
      error: err => {
        this.error = err.error?.detail || 'Upgrade failed. Please sign in and try again.';
        this.loading = false;
      },
    });
  }
}
