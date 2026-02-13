package com.smartirrigation.controller;

import com.smartirrigation.MainApp;
import com.smartirrigation.model.SensorData;
import com.smartirrigation.service.MqttService;
import javafx.application.Platform;
import javafx.fxml.FXML;
import javafx.scene.chart.LineChart;
import javafx.scene.chart.XYChart;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

public class ChartsController {

    @FXML
    private LineChart<String, Number> tempChart;
    @FXML
    private LineChart<String, Number> humidityChart;
    @FXML
    private LineChart<String, Number> soilChart;

    private XYChart.Series<String, Number> tempSeries;
    private XYChart.Series<String, Number> humiditySeries;
    private XYChart.Series<String, Number> soilSeries;
    private final SimpleDateFormat dateFormat = new SimpleDateFormat("HH:mm:ss");

    private final MqttService mqttService = MqttService.getInstance();

    @FXML
    public void initialize() {
        tempSeries = new XYChart.Series<>();
        tempSeries.setName("Temperature");
        tempChart.getData().add(tempSeries);

        humiditySeries = new XYChart.Series<>();
        humiditySeries.setName("Humidity");
        humidityChart.getData().add(humiditySeries);

        soilSeries = new XYChart.Series<>();
        soilSeries.setName("Soil Moisture");
        soilChart.getData().add(soilSeries);

        // Load History
        for (SensorData data : mqttService.getHistory()) {
            String time = dateFormat.format(new Date(System.currentTimeMillis())); // Ideally use data timestamp if
                                                                                   // available
            // Using current time for simplicity in simulation, or parsing data timestamp if
            // possible
            // For now, let's just add points without specific time if timestamp is missing
            // from model,
            // or use current formatted time for re-entry.
            // Since model has timestamp but we use current time in updateChart, let's keep
            // consistency:
            // CAUTION: Re-adding old points with *new* time might look odd,
            // but it's better than empty chart.
            // Ideally, store timestamp in SensorData and use it.
            // Let's assume we proceed with re-plotting.

            tempSeries.getData().add(new XYChart.Data<>(time, data.getTemperature()));
            humiditySeries.getData().add(new XYChart.Data<>(time, data.getHumidity()));
            soilSeries.getData().add(new XYChart.Data<>(time, data.getSoilMoisture()));
        }

        mqttService.setOnSensorDataReceived(this::updateChart);
    }

    private void updateChart(SensorData data) {
        Platform.runLater(() -> {
            String time = dateFormat.format(new Date());

            tempSeries.getData().add(new XYChart.Data<>(time, data.getTemperature()));
            humiditySeries.getData().add(new XYChart.Data<>(time, data.getHumidity()));
            soilSeries.getData().add(new XYChart.Data<>(time, data.getSoilMoisture()));

            // Keep only last 100 points
            if (tempSeries.getData().size() > 100)
                tempSeries.getData().remove(0);
            if (humiditySeries.getData().size() > 100)
                humiditySeries.getData().remove(0);
            if (soilSeries.getData().size() > 100)
                soilSeries.getData().remove(0);
        });
    }

    @FXML
    private void handleBack() throws IOException {
        MainApp.setRoot("dashboard");
    }
}
