import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

// Required by sockjs-client in the browser bundle
(window as unknown as { global: typeof window }).global = window;

bootstrapApplication(AppComponent, appConfig)
  .catch((err) => console.error(err));
