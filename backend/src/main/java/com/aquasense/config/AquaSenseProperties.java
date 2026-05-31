package com.aquasense.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "aquasense")
public record AquaSenseProperties(
        Jwt jwt,
        Cors cors,
        Mqtt mqtt,
        Stripe stripe,
        Mail mail) {

    public record Jwt(String secret, long accessTokenExpirationMs, long refreshTokenExpirationMs) {}

    public record Cors(String allowedOrigins) {}

    public record Mqtt(String host, int port, String username, String password, String telemetryTopic, String commandTopic) {}

    public record Stripe(String apiKey, String webhookSecret, String proPriceId, String successUrl, String cancelUrl) {}

    public record Mail(boolean enabled, String to, String from, String subjectPrefix) {}
}
