package com.smartirrigation.controller;

import com.smartirrigation.MainApp;
import com.smartirrigation.service.MqttService;
import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.control.Label;
import javafx.scene.layout.StackPane;

import java.io.IOException;

public class DashboardController {

    @FXML
    private StackPane contentArea;
    @FXML
    private Label connectionStatus;
    @FXML
    private Label userLabel;

    private final MqttService mqttService = MqttService.getInstance();

    @FXML
    public void initialize() {
        // Setup MQTT callbacks for global status
        mqttService.connect();
        mqttService.setOnConnectionStatusChanged(this::updateConnectionStatus);

        if (LoginController.currentUser != null) {
            userLabel.setText("User: " + LoginController.currentUser.getUsername());
        }

        // Load Default View (Home)
        handleHome();
    }

    private void updateConnectionStatus(boolean isConnected) {
        Platform.runLater(() -> {
            if (isConnected) {
                connectionStatus.setText("Online");
                connectionStatus.setStyle("-fx-text-fill: #4CAF50; -fx-font-weight: bold;");
            } else {
                connectionStatus.setText("Offline");
                connectionStatus.setStyle("-fx-text-fill: #e53935; -fx-font-weight: bold;");
            }
        });
    }

    @FXML
    private void handleHome() {
        loadView("home_view");
    }

    @FXML
    private void handleCharts() {
        loadView("charts");
    }

    @FXML
    private void handleSettings() {
        if ("ADMIN".equals(LoginController.currentUser.getRole())) {
            loadView("settings");
        } else {
            javafx.scene.control.Alert alert = new javafx.scene.control.Alert(
                    javafx.scene.control.Alert.AlertType.WARNING);
            alert.setTitle("Access Denied");
            alert.setHeaderText("Insufficient Permissions");
            alert.setContentText("Only Administrators can access the Settings menu.");
            alert.showAndWait();
        }
    }

    private void loadView(String fxml) {
        try {
            FXMLLoader loader = new FXMLLoader(getClass().getResource("/fxml/" + fxml + ".fxml"));
            Parent view = loader.load();
            contentArea.getChildren().clear();
            contentArea.getChildren().add(view);
        } catch (IOException e) {
            System.err.println("ERROR: Failed to load view: " + fxml);
            e.printStackTrace();
        } catch (Exception e) {
            System.err.println("ERROR: Unexpected error loading view: " + fxml);
            e.printStackTrace();
        }
    }

    @FXML
    private void handleLogout() throws IOException {
        mqttService.disconnect();
        LoginController.currentUser = null;
        MainApp.setRoot("login", 400, 550);
    }
}
