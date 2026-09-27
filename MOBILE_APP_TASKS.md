# AquaSense Mobile App — Task List

This task list is for building a mobile app (iOS + Android) for **AquaSense**. The app uses the existing Spring Boot backend in `backend/`.
Every feature below matches something the backend already exposes. Where the backend needs a small change before mobile can use it, the task is listed under **Phase 0 — Backend prerequisites**.

> Suggested stack: **Flutter** or **React Native (Expo)**. The tasks don't depend on the framework you pick.

---

## Backend reference (what exists today)

**Base URL**
- Dev profile: `http://<host>:8081` (`application-dev.yml`)
- Default profile: `http://<host>:8080`
- WebSocket (STOMP over SockJS): `/ws`. Native clients connect to the raw WebSocket at **`ws://<host>:<port>/ws/websocket`**.

**Seed admin account:** `admin@aquasense.io` / `admin123` (ADMIN role, Pro active)

### REST endpoints

| # | Method | Path | Auth | Body / Params | Response |
|---|--------|------|------|---------------|----------|
| 1 | GET | `/api/public/info` | none | – | `{ name, tagline, description, features[], desktopApp{name,sync,platform} }` |
| 2 | GET | `/api/public/pricing` | none | – | `{ plans: [{ id, name, price, currency, interval?, features[] }] }` |
| 3 | POST | `/api/contact` | none | `{ name(≤100), email(≤120), message(≤2000) }` | `201` (or `503` if mail fails) |
| 4 | POST | `/api/auth/register` | none | `{ fullName(≤100), email(≤80), password(8–100) }` | `201 UserResponse` / `409` email taken |
| 5 | POST | `/api/auth/login` | none | `{ email, password }` | `UserResponse` + `Set-Cookie: access_token, refresh_token` |
| 6 | POST | `/api/auth/refresh` | refresh cookie | – | `UserResponse` + new cookies / `401` |
| 7 | POST | `/api/auth/logout` | – | – | `204`, clears cookies |
| 8 | GET | `/api/auth/me` | access | – | `UserResponse` |
| 9 | GET | `/api/pro/sensors?page=0&size=50` | access + Pro | – | Spring `Page<SensorReadingDto>` (`content[]`, `totalElements`, `totalPages`, `number`, `size`, …), newest first |
| 10 | GET | `/api/pro/connection` | access + Pro | – | `{ mqttConnected: boolean }` |
| 11 | POST | `/api/pro/valve` | access + Pro | `{ action: "OPEN" \| "CLOSE" }` | `202` |
| 12 | POST | `/api/subscription/checkout` | access | – | `{ checkoutUrl }` (Stripe hosted page) |
| 13 | POST | `/api/subscription/complete?session_id=…` | access | – | updated `UserResponse` |
| 14 | GET | `/api/tracking/active` | access + Pro | – | `TrackingInfoResponse` or `204` if none |
| 15 | GET | `/api/tracking/{sessionId}` | access + Pro | – | `TrackingInfoResponse` |
| 16 | POST | `/api/tracking/start` | access | `{ customerId, technicianName, destinationLatitude, destinationLongitude }` | `{ sessionId, trackingToken }` |
| 17 | POST | `/api/tracking/location` | none (token in body) | `{ trackingToken, latitude, longitude, accuracy?, speed?, timestamp? }` | `200` |
| 18 | POST | `/api/tracking/{sessionId}/arrived?token=<uuid>` | none / token | – | `200` |

Pro-only endpoints return `402 Payment Required` for users without Pro. Errors use Spring `ProblemDetail` JSON (`{ title, status, detail }`).

### Models
```
UserResponse        { id, email, fullName, role: "USER"|"ADMIN", subscriptionStatus: "NONE"|"ACTIVE"|"CANCELED"|"PAST_DUE", pro: boolean }
SensorReadingDto    { id, temperature, humidity, soilMoisture, recordedAt (ISO-8601) }
TrackingInfoResponse{ sessionId, technicianName, status: "ACTIVE"|"ARRIVED"|"CANCELLED",
                      currentLatitude, currentLongitude, destinationLatitude, destinationLongitude,
                      currentSpeed (m/s), distanceRemaining (m), lastUpdate, estimatedArrival }
```

### WebSocket topics (STOMP)
| Topic | Payload | Trigger |
|-------|---------|---------|
| `/topic/sensors` | `SensorReadingDto` | Every MQTT telemetry message from the ESP32 |
| `/topic/connection` | `true` / `false` | Sent with each telemetry message |
| `/topic/tracking/{sessionId}` | `TrackingInfoResponse` | Each technician location update and on "arrived" |

---

## Phase 0 — Backend prerequisites (small changes needed for mobile)

These are blockers or strong recommendations. The current backend was built for a browser client.

- [ ] **B1. Token auth for mobile (blocker).** Auth is **cookie-only**. `JwtAuthenticationFilter` reads just the `access_token` cookie, and `/refresh` reads just the `refresh_token` cookie. Changes:
  - In `JwtAuthenticationFilter`, also accept `Authorization: Bearer <token>`.
  - Add a mobile login variant (for example `POST /api/auth/mobile/login` or a `?client=mobile` flag) that returns `{ user, accessToken, refreshToken, expiresIn }` in the body.
  - Let `/api/auth/refresh` accept the refresh token in the body or header.
  - *Alternative (no backend change):* use a persistent cookie jar in the app. This is less reliable on some platforms and not recommended.
- [ ] **B2. Stripe return URLs for mobile.** `success-url` and `cancel-url` point to `http://localhost:4200/...`. Let `/api/subscription/checkout` take a `platform=mobile` parameter that uses deep links such as `aquasense://checkout/success?session_id={CHECKOUT_SESSION_ID}` and `aquasense://pricing?checkout=cancelled`. You could also use universal links or app links.
- [ ] **B3. Tracking error codes.** `TrackingService` throws `IllegalArgumentException` and `IllegalStateException`, and the backend returns these as **500**. Map them in `GlobalExceptionHandler` or switch to `ResponseStatusException`: not found → 404, not Pro → 402, session not active → 409.
- [ ] **B4. Tracking ownership check.** `GET /api/tracking/{sessionId}` doesn't check that the session belongs to the current user. Enable the check that is commented out in `TrackingService.getTrackingInfo`.
- [ ] **B5. Valve feedback.** `POST /api/pro/valve` returns `202` even when MQTT is disconnected, because the command is dropped silently. Return `503` when `!mqttBridgeService.isConnected()`. Optionally add `GET /api/pro/valve/history` (the `ValveCommand` entity is already saved) and a "last known valve state".
- [ ] **B6. WebSocket auth (recommended).** `/ws/**` is `permitAll`, so anyone can subscribe to sensor and tracking topics. Validate the JWT on the STOMP `CONNECT` frame (`Authorization` header).
- [ ] **B7. Push notifications (optional).** Add a `device_tokens` table and a `POST /api/devices` endpoint (FCM/APNs token). Send pushes for: technician arrived, soil moisture below threshold, subscription activated.
- [ ] **B8. Sensor history by time range (optional).** Add `GET /api/pro/sensors?from=&to=` so charts don't have to page through all readings.
- [ ] **B9. Move secrets out of `application.yml`.** The Stripe key, MQTT password and mail password are hard-coded as defaults. Rotate them and load them from environment variables before you ship a mobile build that points at a public server.

---

## Phase 1 — Project setup

- [ ] **M1.1** Create the mobile project (Flutter or RN/Expo), with folders for `api/`, `models/`, `features/`, `widgets/`, `theme/`.
- [ ] **M1.2** Environment config: `API_BASE_URL`, `WS_URL`. Note that the Android emulator uses `10.0.2.2` to reach localhost, and a physical device needs the machine's LAN IP.
- [ ] **M1.3** Allow cleartext HTTP in dev (Android `usesCleartextTraffic` / iOS ATS exception), because the dev backend runs without SSL.
- [ ] **M1.4** Theme matching the web app (`frontend/src/styles/_theme.scss`): colours, typography, light and dark mode.
- [ ] **M1.5** Navigation: a public stack (Welcome, Login, Register, Pricing, About, Contact) and a Pro tab bar (Dashboard, Charts, Valve, Tracking, Account).
- [ ] **M1.6** Typed models for `UserResponse`, `SensorReadingDto`, `TrackingInfoResponse`, `Plan`, `ProjectInfo`, `ProblemDetail`.

## Phase 2 — Networking layer

- [ ] **M2.1** HTTP client with a base URL, JSON handling and a 15 s timeout.
- [ ] **M2.2** Auth interceptor: attach `Authorization: Bearer` (after B1). On `401`, call `/api/auth/refresh` once, retry the request, and log out if the refresh fails. The access token lasts **15 min** and the refresh token **7 days**.
- [ ] **M2.3** Secure token storage (Keychain / Keystore via `flutter_secure_storage` or `expo-secure-store`).
- [ ] **M2.4** Error mapper: parse `ProblemDetail.detail` into user-facing messages. Handle `402` specially by sending the user to the Upgrade screen.
- [ ] **M2.5** STOMP client (`stomp_dart_client` / `@stomp/stompjs`) on `ws://host/ws/websocket`, with auto-reconnect (5 s, like the web app). Reconnect when the app returns to the foreground and disconnect when it goes to the background.

## Phase 3 — Public features (no login)

- [ ] **M3.1 Welcome / About screen**: `GET /api/public/info`. Show the tagline, description, feature list and the desktop app info card.
- [ ] **M3.2 Pricing screen**: `GET /api/public/pricing`. Show Free and Pro plan cards. "Upgrade" goes to login if the user is signed out, otherwise to checkout (M5.1).
- [ ] **M3.3 Contact form**: `POST /api/contact`. Validate client-side (name ≤100, valid email ≤120, message ≤2000). Show the `503` message if the email can't be sent.

## Phase 4 — Authentication

- [ ] **M4.1 Register screen**: `POST /api/auth/register`. Validate: full name required, valid email, password ≥ 8. Show "Email already registered" on `409`. After success, log in automatically.
- [ ] **M4.2 Login screen**: `POST /api/auth/login`. Store the tokens and the user.
- [ ] **M4.3 Session restore on launch**: `GET /api/auth/me`, refresh if needed, then route to the Pro tabs (if `pro` or `role == ADMIN`) or to the free home.
- [ ] **M4.4 Logout**: `POST /api/auth/logout`, clear secure storage, disconnect STOMP.
- [ ] **M4.5 Route guards**: the Pro tabs are only reachable when `user.pro || user.role == "ADMIN"`. Otherwise show the Upgrade CTA (same as the web `proGuard`).

## Phase 5 — Subscription (Stripe)

- [ ] **M5.1 Checkout**: `POST /api/subscription/checkout`, then open `checkoutUrl` in an in-app browser (SFSafariViewController / Custom Tabs).
- [ ] **M5.2 Deep-link return** (needs B2): handle `aquasense://checkout/success?session_id=…`, call `POST /api/subscription/complete?session_id=…`, update the stored user, and show a success screen that unlocks the Pro tabs.
- [ ] **M5.3 Cancel return**: handle `aquasense://pricing?checkout=cancelled` and show a "Checkout cancelled" message.
- [ ] **M5.4 Account screen**: name, email, role, and a `subscriptionStatus` badge (NONE / ACTIVE / CANCELED / PAST_DUE).
- [ ] **M5.5** Check the app-store rules for selling digital subscriptions through Stripe, and decide between an external-purchase link and in-app purchase.

## Phase 6 — Pro: live sensor dashboard

- [ ] **M6.1 Dashboard**: load the latest reading from `GET /api/pro/sensors?page=0&size=1` and show three tiles: temperature (°C), air humidity (%), soil moisture (%).
- [ ] **M6.2 Live updates**: subscribe to `/topic/sensors` and update the tiles as readings arrive. Show a "last updated X s ago" label.
- [ ] **M6.3 Connection status**: `GET /api/pro/connection` on load and pull-to-refresh, plus `/topic/connection`. Show an "IoT online / offline" badge and a WebSocket "Live / Disconnected" badge.
- [ ] **M6.4 Soil moisture hints**: colour thresholds (dry / ok / wet). Optionally show a local notification when moisture drops below a user-set threshold while the app is open.

## Phase 7 — Pro: charts & history

- [ ] **M7.1 Charts screen** (same as web `/pro/charts`): line charts for temperature, humidity and soil moisture from `GET /api/pro/sensors?size=50`. Reverse the result so the charts show oldest to newest.
- [ ] **M7.2** Add live points from `/topic/sensors` to the charts, keeping a rolling window of N points.
- [ ] **M7.3 History list**: a paginated list with infinite scroll (`page++` until `number >= totalPages-1`).
- [ ] **M7.4** Range selector (1 h / 24 h / 7 d). This works client-side now and can switch to the `from/to` query once B8 is done.
- [ ] **M7.5** Export or share the visible data as CSV (same feature as the desktop `CsvExporter`).

## Phase 8 — Pro: valve / pump control

- [ ] **M8.1 Valve screen**: large OPEN / CLOSE buttons that call `POST /api/pro/valve { action }`. The backend sends `PUMP_ON` / `PUMP_OFF` over MQTT to the ESP32.
- [ ] **M8.2** Ask for confirmation before OPEN, and disable the buttons while the request is in flight.
- [ ] **M8.3** Disable the controls when `mqttConnected == false`, and handle `503` once B5 is done.
- [ ] **M8.4** Show the effect: watch the next soil-moisture readings on `/topic/sensors`. Once B5 adds the endpoint, show the valve command history.

## Phase 9 — Pro: technician tracking (customer view)

- [ ] **M9.1 Tracking screen**: `GET /api/tracking/active`. On `204`, show "No active tracking session".
- [ ] **M9.2 Map**: `google_maps_flutter` / `react-native-maps`, with a technician marker (`currentLatitude/Longitude`), a destination marker, and a line between them.
- [ ] **M9.3 Live updates**: subscribe to `/topic/tracking/{sessionId}` and move the marker smoothly.
- [ ] **M9.4 Info card**: technician name, last update, distance remaining (m → km), ETA (`estimatedArrival`). Show "--" for null values (ETA is only computed when `speed > 0`).
- [ ] **M9.5 Arrived state**: when `status == ARRIVED`, show a banner, grey out the map and unsubscribe. Optionally send a push notification (B7).

## Phase 10 — Technician mode (optional, uses existing public endpoints)

This could replace the Apple Shortcut currently used for GPS updates.

- [ ] **M10.1** Admin-only "Start job" form: `POST /api/tracking/start` with the customer ID, technician name and destination (pick it on a map). Show the `trackingToken` or share it as a QR code or link.
- [ ] **M10.2 Technician screen**: enter or scan the `trackingToken`, then start sending location.
- [ ] **M10.3** Background location: send `POST /api/tracking/location { trackingToken, latitude, longitude, accuracy, speed, timestamp }` every 10–15 s. Request "always" location permission with a clear explanation.
- [ ] **M10.4** "I've arrived" button: `POST /api/tracking/{sessionId}/arrived?token=<uuid>`, then stop location updates.

## Phase 11 — Quality & release

- [ ] **M11.1** Loading, empty and error states on every screen; an offline banner.
- [ ] **M11.2** Unit tests for the API client, token refresh and model parsing. Widget/component tests for the login and dashboard screens.
- [ ] **M11.3** End-to-end smoke test against the dev backend (H2 profile, `./backend/run-dev.sh`) using the seed admin account.
- [ ] **M11.4** Point production builds at an HTTPS backend (`wss://` for STOMP), and turn on secure cookies / SSL on the server.
- [ ] **M11.5** App icons, splash screen, store listings, privacy policy (covering location and payment data).

---

## Feature ↔ backend mapping (summary)

| Mobile feature | Endpoints / topics | Web equivalent |
|----------------|--------------------|----------------|
| About / landing | `GET /api/public/info` | `pages/landing`, `pages/about` |
| Pricing | `GET /api/public/pricing` | `pages/pricing` |
| Contact | `POST /api/contact` | `pages/contact` |
| Register / Login / Logout / Session | `/api/auth/*` | `pages/login`, `pages/register` |
| Upgrade to Pro | `/api/subscription/checkout`, `/complete` | `pages/pricing`, `pages/checkout-success` |
| Live dashboard | `/api/pro/sensors`, `/api/pro/connection`, `/topic/sensors`, `/topic/connection` | `pages/charts` |
| Charts / history | `/api/pro/sensors?page&size` | `pages/charts` |
| Valve control | `POST /api/pro/valve` | desktop app (not in web UI yet) |
| Technician tracking | `/api/tracking/active`, `/{id}`, `/topic/tracking/{id}` | `pages/tracking` |
| Technician mode | `/api/tracking/start`, `/location`, `/{id}/arrived` | Apple Shortcut |
