package com.smartirrigation;

import com.smartirrigation.db.DatabaseManager;
import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

import javafx.application.Platform;
import java.io.IOException;

public class MainApp extends Application {

    private static Scene scene;
    private static Stage primaryStage;

    @Override
    public void start(Stage stage) throws IOException {
        primaryStage = stage;
        DatabaseManager.initializeDatabase(); // Verify DB exists

        scene = new Scene(loadFXML("login"), 400, 550);
        scene.getStylesheets().add(getClass().getResource("/css/style.css").toExternalForm());

        stage.setOnCloseRequest(event -> {
            System.out.println("Closing application...");
            try {
                com.smartirrigation.service.MqttService.getInstance().disconnect();
            } catch (Exception e) {
                e.printStackTrace();
            }
            Platform.exit();
            System.exit(0);
        });

        stage.setTitle("Smart Irrigation System");
        stage.setScene(scene);
        stage.show();
    }

    public static void setRoot(String fxml) throws IOException {
        scene.setRoot(loadFXML(fxml));
    }

    public static void setRoot(String fxml, double width, double height) throws IOException {
        scene.setRoot(loadFXML(fxml));
        primaryStage.setWidth(width);
        primaryStage.setHeight(height);
        primaryStage.centerOnScreen();
    }

    public static Stage getPrimaryStage() {
        return primaryStage;
    }

    private static Parent loadFXML(String fxml) throws IOException {
        FXMLLoader fxmlLoader = new FXMLLoader(MainApp.class.getResource("/fxml/" + fxml + ".fxml"));
        return fxmlLoader.load();
    }

    public static void main(String[] args) {
        launch();
    }
}
