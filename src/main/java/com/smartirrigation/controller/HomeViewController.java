package com.smartirrigation.controller;

import com.smartirrigation.dao.ValveActionDAO;
import com.smartirrigation.model.SensorData;
import com.smartirrigation.service.MqttService;
import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.layout.VBox;

public class HomeViewController {

    @FXML
    private Label tempLabel;
    @FXML
    private Label humidityLabel;
    @FXML
    private Label soilLabel;
    @FXML
    private Button valveButton;
    @FXML
    private VBox valveIndicator;

    private boolean isValveOpen = false;
    private final MqttService mqttService = MqttService.getInstance();
    private final ValveActionDAO valveActionDAO = new ValveActionDAO();

    @FXML
    public void initialize() {
        // mqttService.connect(); // Handled by DashboardController

        // Restore State
        if (mqttService.getLastSensorData() != null) {
            updateSensorData(mqttService.getLastSensorData());
        }

        mqttService.setOnSensorDataReceived(this::updateSensorData);
        updateValveUI();
    }

    private void updateSensorData(SensorData data) {
        javafx.application.Platform.runLater(() -> {
            if (tempLabel == null)
                return; // Safety check
            tempLabel.setText(String.format("%.1f", data.getTemperature()));
            humidityLabel.setText(String.format("%.1f", data.getHumidity()));
            soilLabel.setText(String.format("%.1f", data.getSoilMoisture()));

            // Check thresholds and automate
            checkThresholdsAndAutomate(data);
        });
    }

    private void checkThresholdsAndAutomate(SensorData data) {
        boolean shouldOpenValve = false;

        // Fire danger check - Temperature > 60°C
        if (data.getTemperature() > 60) {
            javafx.scene.control.Alert alert = new javafx.scene.control.Alert(
                    javafx.scene.control.Alert.AlertType.WARNING);
            alert.setTitle("Fire Potential!");
            alert.setHeaderText("⚠️ High Temperature Detected");
            alert.setContentText(String.format(
                    "Temperature: %.1f°C\n\nValve opening automatically for safety.",
                    data.getTemperature()));
            alert.show();
            shouldOpenValve = true;
        }

        // Dry conditions check
        if (data.getHumidity() < 30) {
            System.out.println("Low humidity detected: " + data.getHumidity() + "% - Auto-opening valve");
            shouldOpenValve = true;
        }

        if (data.getSoilMoisture() < 20) {
            System.out.println("Low soil moisture detected: " + data.getSoilMoisture() + "% - Auto-opening valve");
            shouldOpenValve = true;
        }

        // Auto-open valve if needed and currently closed
        if (shouldOpenValve && !isValveOpen) {
            System.out.println("AUTO-CONTROL: Opening valve due to threshold violation");
            handleToggleValve();
        }
    }

    @FXML
    private void handleToggleValve() {
        isValveOpen = !isValveOpen;
        String action = isValveOpen ? "OPEN" : "CLOSE";

        mqttService.publishValveCommand(action);
        if (LoginController.currentUser != null) {
            valveActionDAO.logAction(LoginController.currentUser.getId(), action);
        }

        updateValveUI();
    }

    private void updateValveUI() {
        if (isValveOpen) {
            valveButton.setText("Close Valve");
            valveButton.setStyle("-fx-background-color: linear-gradient(to bottom right, #ef5350 0%, #e53935 100%);");
            valveIndicator.setStyle(
                    "-fx-background-color: #4CAF50; " +
                            "-fx-background-radius: 50; " +
                            "-fx-effect: dropshadow(gaussian, rgba(76, 175, 80, 0.8), 20, 0.6, 0, 0);");
        } else {
            valveButton.setText("Open Valve");
            valveButton.setStyle("-fx-background-color: linear-gradient(to bottom right, #66BB6A 0%, #43A047 100%);");
            valveIndicator.setStyle(
                    "-fx-background-color: #e0e0e0; " +
                            "-fx-background-radius: 50; " +
                            "-fx-effect: dropshadow(gaussian, rgba(0, 0, 0, 0.2), 8, 0, 0, 2);");
        }
    }
}
