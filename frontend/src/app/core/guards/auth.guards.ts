import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { map, catchError, of } from 'rxjs';
import { AuthService } from '../services/auth.service';

export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  return auth.restoreSession().pipe(
    map(user => {
      if (user) return true;
      router.navigate(['/login']);
      return false;
    }),
    catchError(() => {
      router.navigate(['/login']);
      return of(false);
    })
  );
};

/** Requires an active Pro subscription (or admin). Always checks the server for fresh status. */
export const proGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  return auth.me().pipe(
    map(user => {
      if (user.pro || user.role === 'ADMIN') return true;
      router.navigate(['/pricing']);
      return false;
    }),
    catchError(() => {
      router.navigate(['/login']);
      return of(false);
    })
  );
};

export const guestGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  return auth.restoreSession().pipe(
    map(user => {
      if (user) {
        router.navigate([user.pro || user.role === 'ADMIN' ? '/charts' : '/']);
        return false;
      }
      return true;
    }),
    catchError(() => of(true))
  );
};
