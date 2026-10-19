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

- [x] **B1. Token auth for mobile (blocker).** Auth supports `Authorization: Bearer <token>`, `POST /api/auth/mobile/login` and `POST /api/auth/mobile/refresh`.
- [x] **B2. Stripe return URLs for mobile.** `/api/subscription/checkout?platform=mobile` parameter generates `aquasense://checkout/success?session_id=...` deep link URLs.
- [x] **B3. Tracking error codes.** `GlobalExceptionHandler` maps `IllegalArgumentException` (404) and `IllegalStateException` (402/409) to problem details.
- [x] **B4. Tracking ownership check.** `getTrackingInfo` verifies that session belongs to the current user or admin.
- [x] **B5. Valve feedback.** `POST /api/pro/valve` returns `503` when `mqttBridgeService` is disconnected.
- [x] **B6. WebSocket auth & native endpoint.** Added native WebSocket endpoint `/ws` alongside `.withSockJS()`.
- [ ] **B7. Push notifications (optional).** Add a `device_tokens` table and a `POST /api/devices` endpoint (FCM/APNs token). Send pushes for: technician arrived, soil moisture below threshold, subscription activated.
- [ ] **B8. Sensor history by time range (optional).** Add `GET /api/pro/sensors?from=&to=` so charts don't have to page through all readings.
- [ ] **B9. Move secrets out of `application.yml`.** The Stripe key, MQTT password and mail password are hard-coded as defaults. Rotate them and load them from environment variables before you ship a mobile build that points at a public server.

---

## Phase 1 — Project setup

- [x] **M1.1** Create the mobile project (Flutter), with folders for `core/`, `features/`, `widgets/`, `theme/`.
- [x] **M1.2** Environment config: `API_BASE_URL`, `WS_URL`.
- [x] **M1.3** Allow cleartext HTTP in dev (`usesCleartextTraffic`).
- [x] **M1.4** Theme matching the web app: colours, typography, light/dark mode in `app_theme.dart`.
- [x] **M1.5** Navigation: public stack and Pro tab bar shell (`main_tab_screen.dart`).
- [x] **M1.6** Typed models for `UserResponse`, `SensorReading`, `TrackingInfoResponse`, `Plan`, `ProjectInfo`.

## Phase 2 — Networking layer

- [x] **M2.1** HTTP client with base URL, JSON handling and 15 s timeout (`api_client.dart`).
- [x] **M2.2** Auth interceptor: attach `Authorization: Bearer`, automatic token refresh on `401`.
- [x] **M2.3** Secure token storage (`flutter_secure_storage`).
- [x] **M2.4** Error mapper: parse `ProblemDetail.detail` into `ApiException`.
- [x] **M2.5** STOMP client (`stomp_dart_client`) on `ws://host/ws/websocket`, with auto-reconnect.

## Phase 3 — Public features (no login)

- [x] **M3.1 Welcome / About screen**: `GET /api/public/info` (`welcome_screen.dart`).
- [x] **M3.2 Pricing screen**: `GET /api/public/pricing` (`pricing_screen.dart`).
- [x] **M3.3 Contact form**: `POST /api/contact` (`contact_screen.dart`).

## Phase 4 — Authentication

- [x] **M4.1 Register screen**: `POST /api/auth/register` with validation.
- [x] **M4.2 Login screen**: `POST /api/auth/mobile/login`, token storage.
- [x] **M4.3 Session restore on launch**: `GET /api/auth/me`.
- [x] **M4.4 Logout**: `POST /api/auth/logout`, clear storage.
- [x] **M4.5 Route guards**: Pro features guarded for `pro || role == "ADMIN"`, with Upgrade CTA for free tier.

## Phase 5 — Subscription (Stripe)

- [x] **M5.1 Checkout**: `POST /api/subscription/checkout?platform=mobile`, open checkout in browser via `url_launcher`.
- [x] **M5.2 Deep-link return**: handle `aquasense://checkout/success?session_id=…`, call `POST /api/subscription/complete`.
- [x] **M5.3 Cancel return**: handle `aquasense://pricing?checkout=cancelled`.
- [x] **M5.4 Account screen**: name, email, role, and subscription status badge on `HomeScreen`.

## Phase 6 — Pro: live sensor dashboard

- [x] **M6.1 Dashboard**: load latest reading from `GET /api/pro/sensors?page=0&size=1`.
- [x] **M6.2 Live updates**: subscribe to `/topic/sensors` and update tiles in real-time.
- [x] **M6.3 Connection status**: `GET /api/pro/connection` + `/topic/connection` badges.
- [x] **M6.4 Soil moisture hints**: colour thresholds (Dry / Optimal / Wet).

## Phase 7 — Pro: charts & history

- [x] **M7.1 Charts screen**: line charts for temperature, humidity and soil moisture (`fl_chart`).
- [x] **M7.2** Add live points from `/topic/sensors` to the charts.
- [x] **M7.3 History list**: paginated readings list.
- [x] **M7.4 Range / Tab selector**: view live analytics vs history list.
- [x] **M7.5** Export or share visible data as CSV (`share_plus`).

## Phase 8 — Pro: valve / pump control

- [x] **M8.1 Valve screen**: OPEN / CLOSE buttons for `POST /api/pro/valve`.
- [x] **M8.2** Confirmation dialog before OPEN.
- [x] **M8.3** Disable controls when `mqttConnected == false` and handle `503`.
- [x] **M8.4** Visual indicator showing last command state.

## Phase 9 — Pro: technician tracking (customer view)

- [x] **M9.1 Tracking screen**: `GET /api/tracking/active`.
- [x] **M9.2 Location Display**: Technician name, current/destination metrics.
- [x] **M9.3 Live updates**: subscribe to `/topic/tracking/{sessionId}`.
- [x] **M9.4 Info card**: distance remaining (km), ETA, speed, last update fix.
- [x] **M9.5 Arrived state**: status banner on `ARRIVED`.

## Phase 10 — Technician mode (optional, uses existing public endpoints)

- [x] **M10.1** Admin "Start job" form: `POST /api/tracking/start` (`technician_screen.dart`).
- [x] **M10.2 Technician screen**: active session token display and location sender.
- [x] **M10.3** Send `POST /api/tracking/location { trackingToken, latitude, longitude, speed }`.
- [x] **M10.4** "I've arrived" button: `POST /api/tracking/{sessionId}/arrived?token=<uuid>`.

## Phase 11 — Quality & release

- [x] **M11.1** Loading, empty and error states on every screen.
- [x] **M11.2** Unit tests for API client, token refresh, validators, models, and widget tests. All tests passing!
- [x] **M11.3** End-to-end build test: APK compiled and verified on Android Emulator.

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
