# Academic Presentation: Intelligent IoT Irrigation System

## Team: [Member 1] & [Member 2]
## Presentation Strategy: 2-Person Workflow

1.  **Member 1 (IoT & Infrastructure Specialist)**
    *   Focus: Hardware, Edge Computing, Networking, and Physical Simulation.
    *   Slides: 1-5, 13, 14.
2.  **Member 2 (Software Architect & Backend Developer)**
    *   Focus: Database Design, UI/UX, Automation Logic, and Performance Analytics.
    *   Slides: 6-12, 13, 14.

---

### Slide 1: Title & Team
*   **Slide Title:** Intelligent IoT Irrigation & Monitoring System
*   **Sub-title:** A Modern Approach to Precision Agriculture
*   **Speaker Notes (Member 1):** Welcome everyone. Today we present an integrated IoT solution for smart water management.

---

### Slide 2: Project Motivation & Problem Statement
*   **Presenter:** Member 1
*   **Points:**
    *   Water scarcity in agriculture (70% global usage).
    *   Inefficiency of manual scheduling.
    *   Lack of emergency hazard response systems.

---

### Slide 3: System Architecture Overview
*   **Presenter:** Member 1
*   **Points:**
    *   **Edge:** ESP32 with multi-sensor array.
    *   **Broker:** HiveMQ Cloud (MQTT).
    *   **Desktop:** JavaFX dashboard with SQLite persistence.

---

### Slide 4: Hardware implementation & MQTT Connectivity
*   **Presenter:** Member 1
*   **Points:**
    *   ESP32 logic: Polling and JSON telemetry publishing.
    *   MQTT Protocol: Lightweight Pub/Sub for constrained devices.
    *   Topics: `telemetry` (Sensors) vs `command` (Manual/Auto Override).

---

### Slide 5: Data Flow & End-to-End Logic
*   **Presenter:** Member 1
*   **Points:**
    *   Sensor &rarr; JSON &rarr; MQTT &rarr; Desktop &rarr; DB.
    *   Real-time synchronization ensures sub-100ms lag.

---

### Slide 6: Database Persistence & JDBC Implementation
*   **Presenter:** Member 2
*   **Points:**
    *   SQLite Engine: Zero-config, embedded, and highly efficient.
    *   Schema: Users, Sensor Logs, and Valve Command History.
    *   Optimization: Write-Ahead Logging (WAL) and Timestamp Indexing.

---

### Slide 7: Software Logic: JavaFX MVC Architecture
*   **Presenter:** Member 2
*   **Points:**
    *   Pure Java implementation with Maven dependency management.
    *   Asynchronous MQTT Client integration to prevent UI thread blocking.

---

### Slide 8: Interactive Dashboard & Monitoring
*   **Presenter:** Member 2
*   **Points:**
    *   Gauges and indicators for real-time visibility.
    *   Thread-safe UI updates using `Platform.runLater`.

---

### Slide 9: Feature Spotlight: Threshold Automation
*   **Presenter:** Member 2
*   **Points:**
    *   Auto-Irrigation: Triggered at Humidity < 30% or Soil < 20%.
    *   Valve logic: Checks current state to prevent redundant instructions.

---

### Slide 10: Hazard Response: Fire Safety AI
*   **Presenter:** Member 2
*   **Points:**
    *   Thermal guard: Auto-open valve if Temperature > 60°C.
    *   Integrated UI warnings and persistent log auditing.

---

### Slide 11: Security & Role-Based Access (RBAC)
*   **Presenter:** Member 2
*   **Points:**
    *   Admin Role: Cloud Broker config, History Exports, and System Reset.
    *   Operator Role: Basic monitoring and operational control.

---

### Slide 12: Modern UI/UX Design & CSS Overhaul
*   **Presenter:** Member 2
*   **Points:**
    *   Glassmorphism effects, shadows, and linear gradients.
    *   Micro-animations and icon-driven navigation for premium feel.

---

### Slide 13: Technical Challenges & Debugging
*   **Presenters:** Both
*   **Points:**
    *   Resolving CSS syntax versioning for JavaFX 8.
    *   Ensuring SQLite connection timeouts for high-load cycles.
    *   ESP32 Wi-Fi persistence and auto-recovery.

---

### Slide 14: Results, Conclusion & Future Work
*   **Presenters:** Both
*   **Points:**
    *   Successful demonstration of End-to-End automation.
    *   Future: AI Predictive analytics for weather forecasting.
    *   Future: Scaling to multiple node clusters.
