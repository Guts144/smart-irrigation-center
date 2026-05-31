package com.aquasense.service;

import com.aquasense.config.AquaSenseProperties;
import com.aquasense.dto.SensorReadingDto;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hivemq.client.mqtt.MqttClient;
import com.hivemq.client.mqtt.mqtt3.Mqtt3AsyncClient;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

@Slf4j
@Service
@RequiredArgsConstructor
public class MqttBridgeService {

    private final AquaSenseProperties properties;
    private final SensorService sensorService;
    private final SimpMessagingTemplate messagingTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private Mqtt3AsyncClient client;
    private final AtomicBoolean connected = new AtomicBoolean(false);

    @PostConstruct
    public void connect() {
        var mqtt = properties.mqtt();
        client = MqttClient.builder()
                .useMqttVersion3()
                .identifier("aquasense-web-" + UUID.randomUUID())
                .serverHost(mqtt.host())
                .serverPort(mqtt.port())
                .sslWithDefaultConfig()
                .simpleAuth()
                .username(mqtt.username())
                .password(mqtt.password().getBytes(StandardCharsets.UTF_8))
                .applySimpleAuth()
                .addConnectedListener(ctx -> connected.set(true))
                .addDisconnectedListener(ctx -> connected.set(false))
                .automaticReconnectWithDefaultConfig()
                .buildAsync();

        client.connectWith().cleanSession(true).send().whenComplete((ack, err) -> {
            if (err != null) {
                log.error("MQTT connection failed: {}", err.getMessage());
            } else {
                log.info("MQTT connected");
                subscribeTelemetry();
            }
        });
    }

    private void subscribeTelemetry() {
        client.subscribeWith()
                .topicFilter(properties.mqtt().telemetryTopic())
                .callback(publish -> {
                    String payload = new String(publish.getPayloadAsBytes(), StandardCharsets.UTF_8);
                    handleTelemetry(payload);
                })
                .send();
    }

    private void handleTelemetry(String json) {
        try {
            JsonNode node = objectMapper.readTree(json);
            double temperature = node.path("temperature").asDouble();
            double humidity = node.path("humidity").asDouble();
            double soilMoisture = node.has("soil_moisture")
                    ? node.path("soil_moisture").asDouble()
                    : node.path("soilMoisture").asDouble();

            var saved = sensorService.saveReading(temperature, humidity, soilMoisture);
            SensorReadingDto dto = sensorService.toDto(saved);
            messagingTemplate.convertAndSend("/topic/sensors", dto);
            messagingTemplate.convertAndSend("/topic/connection", connected.get());
        } catch (Exception e) {
            log.error("Failed to process telemetry: {}", e.getMessage());
        }
    }

    public void publishValveCommand(String action) {
        if (client == null || !client.getState().isConnected()) {
            return;
        }
        String command = "OPEN".equals(action) ? "PUMP_ON" : "PUMP_OFF";
        String payload = "{\"command\": \"" + command + "\"}";
        client.publishWith()
                .topic(properties.mqtt().commandTopic())
                .payload(payload.getBytes(StandardCharsets.UTF_8))
                .send();
    }

    public boolean isConnected() {
        return connected.get();
    }

    @PreDestroy
    public void disconnect() {
        if (client != null && client.getState().isConnected()) {
            client.disconnect();
        }
    }
}
