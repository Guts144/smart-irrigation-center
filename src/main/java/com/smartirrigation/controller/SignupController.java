package com.smartirrigation.controller;

import com.smartirrigation.MainApp;
import com.smartirrigation.dao.UserDAO;
import javafx.fxml.FXML;
import javafx.scene.control.CheckBox;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;

import java.io.IOException;

public class SignupController {

    @FXML
    private TextField usernameField;
    @FXML
    private PasswordField passwordField;
    @FXML
    private CheckBox adminCheckBox;
    @FXML
    private PasswordField adminCodeField;
    @FXML
    private Label errorLabel;

    private final UserDAO userDAO = new UserDAO();

    @FXML
    public void initialize() {
        // Toggle visibility of admin code field
        adminCodeField.managedProperty().bind(adminCheckBox.selectedProperty());
        adminCodeField.visibleProperty().bind(adminCheckBox.selectedProperty());
    }

    @FXML
    private void handleSignup() {
        String username = usernameField.getText();
        String password = passwordField.getText();
        String role = "USER";

        if (username.isEmpty() || password.isEmpty()) {
            errorLabel.setText("Username/Password cannot be empty");
            errorLabel.setStyle("-fx-text-fill: red;");
            return;
        }

        if (adminCheckBox.isSelected()) {
            if (!"3alsleam2".equals(adminCodeField.getText())) {
                errorLabel.setText("Invalid Admin Code!");
                errorLabel.setStyle("-fx-text-fill: red;");
                return;
            }
            role = "ADMIN";
        }

        if (userDAO.registerUser(username, password, role)) {
            errorLabel.setText("Registration successful!");
            errorLabel.setStyle("-fx-text-fill: green;");
            // Optionally auto-redirect or let user click Back
        } else {
            errorLabel.setText("Username already exists!");
            errorLabel.setStyle("-fx-text-fill: red;");
        }
    }

    @FXML
    private void handleBackToLogin() throws IOException {
        MainApp.setRoot("login", 400, 550);
    }
}
