package com.smartirrigation.service;

import com.google.gson.Gson;
import com.hivemq.client.mqtt.MqttClient;

import com.hivemq.client.mqtt.mqtt3.Mqtt3AsyncClient;

import com.smartirrigation.dao.SensorDataDAO;
import com.smartirrigation.model.SensorData;
import javafx.application.Platform;

import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.function.Consumer;

public class MqttService {
    private static MqttService instance;
    private Mqtt3AsyncClient client;
    private final Gson gson = new Gson();
    private final SensorDataDAO sensorDataDAO = new SensorDataDAO();

    // Default Configuration
    private String host = "003405b159a641e2bed741f8db2e0344.s1.eu.hivemq.cloud";
    private int port = 8883;
    private String username = "mgharsal";
    private String password = "Anzb123.";

    // Callbacks for UI
    private Consumer<SensorData> onSensorDataReceived;
    private Consumer<Boolean> onConnectionStatusChanged;

    private MqttService() {
    }

    public static synchronized MqttService getInstance() {
        if (instance == null) {
            instance = new MqttService();
        }
        return instance;
    }

    public void setConnectionDetails(String host, int port, String username, String password) {
        this.host = host;
        this.port = port;
        this.username = username;
        this.password = password;
    }

    public void connect() {
        if (client != null && client.getState().isConnected()) {
            return;
        }

        client = MqttClient.builder()
                .useMqttVersion3()
                .identifier(UUID.randomUUID().toString())
                .serverHost(host)
                .serverPort(port)
                .sslWithDefaultConfig()
                .simpleAuth()
                .username(username)
                .password(password.getBytes(StandardCharsets.UTF_8))
                .applySimpleAuth()
                .addConnectedListener(context -> updateConnectionStatus(true))
                .addDisconnectedListener(context -> updateConnectionStatus(false))
                .automaticReconnectWithDefaultConfig()
                .buildAsync();

        client.connectWith()
                .cleanSession(true)
                .send()
                .whenComplete((connAck, throwable) -> {
                    if (throwable != null) {
                        System.err.println("Connection failed: " + throwable.getMessage());
                        updateConnectionStatus(false);
                    } else {
                        System.out.println("Connected to HiveMQ: " + connAck.getReturnCode());
                        updateConnectionStatus(true);
                        subscribeToTopics();
                    }
                });
    }

    public void disconnect() {
        if (client != null && client.getState().isConnected()) {
            client.disconnect().whenComplete((ack, throwable) -> {
                if (throwable == null) {
                    System.out.println("Disconnected from MQTT broker");
                }
            });
        }
    }

    private void subscribeToTopics() {
        client.subscribeWith()
                .topicFilter("irrigation/device/esp32_01/telemetry")
                .callback(publish -> {
                    String payload = new String(publish.getPayloadAsBytes(), StandardCharsets.UTF_8);
                    processSensorData(payload);
                })
                .send()
                .whenComplete((subAck, throwable) -> {
                    if (throwable != null) {
                        System.err.println("Subscribe failed: " + throwable.getMessage());
                    } else {
                        System.out.println("Subscribed to irrigation/device/esp32_01/telemetry");
                    }
                });
    }

    public void publishValveCommand(String action) { // "OPEN" or "CLOSE"
        if (client == null || !client.getState().isConnected())
            return;

        String topic = "irrigation/device/esp32_01/command";
        // Convert OPEN/CLOSE to PUMP_ON/PUMP_OFF
        String command = action.equals("OPEN") ? "PUMP_ON" : "PUMP_OFF";
        String payload = "{\"command\": \"" + command + "\"}";

        client.publishWith()
                .topic(topic)
                .payload(payload.getBytes(StandardCharsets.UTF_8))
                .send()
                .whenComplete((publish, throwable) -> {
                    if (throwable != null) {
                        System.err.println("Publish failed: " + throwable.getMessage());
                    } else {
                        System.out.println("Published: " + payload);
                    }
                });
    }

    private final java.util.List<SensorData> history = new java.util.concurrent.CopyOnWriteArrayList<>();
    private SensorData lastSensorData;

    private void processSensorData(String json) {
        try {
            System.out.println("Processing Payload: " + json);
            SensorData data = gson.fromJson(json, SensorData.class);
            // Save to DB
            sensorDataDAO.insertReading(data.getTemperature(), data.getHumidity(), data.getSoilMoisture());

            // Update History
            lastSensorData = data;
            history.add(data);
            if (history.size() > 100) {
                history.remove(0);
            }

            // Update UI
            if (onSensorDataReceived != null) {
                // Determine if we are on FX Thread (we usually aren't here)
                // Let the controller handle Platform.runLater
                onSensorDataReceived.accept(data);
            }
        } catch (Exception e) {
            System.err.println("Error parsing JSON: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public java.util.List<SensorData> getHistory() {
        return history;
    }

    public SensorData getLastSensorData() {
        return lastSensorData;
    }

    public void setOnSensorDataReceived(Consumer<SensorData> listener) {
        this.onSensorDataReceived = listener;
    }

    public void setOnConnectionStatusChanged(Consumer<Boolean> listener) {
        this.onConnectionStatusChanged = listener;
    }

    private void updateConnectionStatus(boolean isConnected) {
        if (onConnectionStatusChanged != null) {
            Platform.runLater(() -> onConnectionStatusChanged.accept(isConnected));
        }
    }

    public String getHost() {
        return host;
    }

    public int getPort() {
        return port;
    }

    public String getUsername() {
        return username;
    }
}
