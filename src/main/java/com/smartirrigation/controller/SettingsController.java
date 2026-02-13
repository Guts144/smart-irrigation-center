package com.smartirrigation.controller;

import com.smartirrigation.MainApp;
import com.smartirrigation.service.MqttService;
import javafx.fxml.FXML;
import javafx.scene.control.TextField;
import javafx.scene.control.PasswordField;
import javafx.scene.control.Label;

import java.io.IOException;

public class SettingsController {

    @FXML
    private TextField hostField;
    @FXML
    private TextField portField;
    @FXML
    private TextField usernameField;
    @FXML
    private PasswordField passwordField;
    @FXML
    private Label statusLabel;

    private final MqttService mqttService = MqttService.getInstance();

    @FXML
    public void initialize() {
        hostField.setText(mqttService.getHost());
        portField.setText(String.valueOf(mqttService.getPort()));
        usernameField.setText(mqttService.getUsername());

        // Listen for connection changes
        mqttService.setOnConnectionStatusChanged(isConnected -> {
            if (isConnected) {
                statusLabel.setText("Connected Successfully!");
                statusLabel.setStyle("-fx-text-fill: green;");
            } else {
                statusLabel.setText("Disconnected / Connection Failed");
                statusLabel.setStyle("-fx-text-fill: red;");
            }
        });
    }

    @FXML
    private void handleSave() {
        try {
            String host = hostField.getText();
            int port = Integer.parseInt(portField.getText());
            String username = usernameField.getText();
            String password = passwordField.getText();

            mqttService.disconnect();
            mqttService.setConnectionDetails(host, port, username, password);
            mqttService.connect();

            statusLabel.setText("Connecting...");
            statusLabel.setStyle("-fx-text-fill: orange;");
        } catch (NumberFormatException e) {
            statusLabel.setText("Invalid Port Number");
            statusLabel.setStyle("-fx-text-fill: red;");
        }
    }

    @FXML
    private void handleExport() {
        try {
            com.smartirrigation.dao.ValveActionDAO valveActionDAO = new com.smartirrigation.dao.ValveActionDAO();
            java.util.List<com.smartirrigation.model.ValveAction> history = valveActionDAO.getAllHistory();
            String filename = "valve_history_" + System.currentTimeMillis() + ".csv";
            com.smartirrigation.util.CsvExporter.exportValveHistory(history, filename);

            statusLabel.setText("Exported to " + filename);
            statusLabel.setStyle("-fx-text-fill: green;");
        } catch (java.io.IOException e) {
            statusLabel.setText("Export Failed: " + e.getMessage());
            statusLabel.setStyle("-fx-text-fill: red;");
        }
    }

    @FXML
    private void handleBack() throws IOException {
        MainApp.setRoot("dashboard");
    }
}
