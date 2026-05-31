package com.aquasense.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/public")
public class PublicController {

    @GetMapping("/info")
    public Map<String, Object> projectInfo() {
        return Map.of(
                "name", "AquaSense",
                "tagline", "Smart Irrigation Management Center",
                "description", "Monitor soil moisture, temperature, and humidity from IoT sensors. "
                        + "Control irrigation valves remotely and sync with the desktop companion app in real time.",
                "features", List.of(
                        "Pro sensor analytics charts",
                        "MQTT-connected IoT sensor network",
                        "Remote valve control via desktop app",
                        "Real-time sync via WebSocket",
                        "Role-based access with Pro subscription"),
                "desktopApp", Map.of(
                        "name", "Smart Irrigation System",
                        "sync", "Real-time STOMP over WebSocket",
                        "platform", "JavaFX desktop"));
    }

    @GetMapping("/pricing")
    public Map<String, Object> pricing() {
        return Map.of(
                "plans", List.of(
                        Map.of("id", "free", "name", "Public", "price", 0, "currency", "USD",
                                "features", List.of("Landing page", "Account registration", "Project info", "Contact form")),
                        Map.of("id", "pro", "name", "Pro", "price", 29, "currency", "USD", "interval", "month",
                                "features", List.of(
                                        "Sensor analytics charts",
                                        "Real-time IoT data",
                                        "Full desktop application access",
                                        "Historical analytics",
                                        "Cloud account sync"))));
    }
}
