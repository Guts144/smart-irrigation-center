package com.smartirrigation.controller;

import com.smartirrigation.MainApp;
import com.smartirrigation.dao.UserDAO;
import com.smartirrigation.model.User;
import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.control.PasswordField;
import javafx.scene.control.TextField;

import java.io.IOException;

public class LoginController {

    @FXML
    private TextField usernameField;
    @FXML
    private PasswordField passwordField;
    @FXML
    private Label errorLabel;

    private final UserDAO userDAO = new UserDAO();
    public static User currentUser;

    @FXML
    private void handleLogin() throws IOException {
        String username = usernameField.getText();
        String password = passwordField.getText();

        User user = userDAO.loginUser(username, password);

        if (user != null) {
            currentUser = user;
            MainApp.setRoot("dashboard", 1024, 768);
        } else {
            errorLabel.setText("Invalid credentials!");
        }
    }

    @FXML
    private void handleGoToSignup() throws IOException {
        MainApp.setRoot("signup", 400, 550);
    }
}
