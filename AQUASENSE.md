# AquaSense — Smart Irrigation Management Center

Full-stack web platform for remote irrigation monitoring, built alongside the existing JavaFX desktop app.

## Architecture

| Layer | Stack |
|-------|-------|
| Frontend | Angular 17 (standalone), Chart.js, STOMP/SockJS |
| Backend | Spring Boot 3.3, Java 21, JWT (HttpOnly cookies) |
| Database | PostgreSQL |
| IoT | HiveMQ Cloud MQTT (shared with desktop app) |
| Payments | Stripe subscriptions (Pro tier) |

## Access tiers

- **Public** — landing, auth, about, contact, pricing
- **Pro** — live sensor dashboard, MQTT data, valve control, WebSocket sync with desktop

## Quick start

### 1. PostgreSQL

```bash
docker compose up -d
```

### 2. Backend

```bash
cd backend
export PATH="/opt/homebrew/bin:$PATH"
mvn spring-boot:run
```

API: `http://localhost:8081` (dev profile; default is 8080)  
Default admin: `admin@aquasense.io` / `admin123` (Pro enabled)

### 3. Frontend

```bash
cd frontend
npm start
```

App: `http://localhost:4200` (proxies `/api` and `/ws` to backend)

## Environment variables

| Variable | Description |
|----------|-------------|
| `JWT_SECRET` | HMAC secret (min 256 bits in production) |
| `STRIPE_API_KEY` | Stripe secret key |
| `STRIPE_PRO_PRICE_ID` | Stripe Price ID for Pro plan |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret |
| `MQTT_*` | HiveMQ broker credentials |

## Desktop app sync

Both the web backend and JavaFX desktop subscribe to the same MQTT topics:

- Telemetry: `irrigation/device/esp32_01/telemetry`
- Commands: `irrigation/device/esp32_01/command`

The web backend persists readings to PostgreSQL and broadcasts via WebSocket (`/topic/sensors`) so the Angular dashboard updates in real time — matching the desktop experience.

## Color theme

Web UI uses the same green palette as `src/main/resources/css/style.css` in the desktop app (`#43A047`, `#1B5E20`, `#e8f5e9` gradient background).

## Project layout

```
backend/          Spring Boot API
frontend/         Angular SPA
docker-compose.yml PostgreSQL
src/              JavaFX desktop app (existing)
esp32_firmware/   IoT device firmware
```
