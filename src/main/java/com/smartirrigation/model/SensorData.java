package com.smartirrigation.model;

import java.sql.Timestamp;

public class SensorData {
    private int id;
    private double temperature;
    private double humidity;
    private double soilMoisture;
    private Timestamp timestamp;

    public SensorData(double temperature, double humidity, double soilMoisture) {
        this.temperature = temperature;
        this.humidity = humidity;
        this.soilMoisture = soilMoisture;
    }

    public SensorData(int id, double temperature, double humidity, double soilMoisture, Timestamp timestamp) {
        this.id = id;
        this.temperature = temperature;
        this.humidity = humidity;
        this.soilMoisture = soilMoisture;
        this.timestamp = timestamp;
    }

    public int getId() { return id; }
    public double getTemperature() { return temperature; }
    public double getHumidity() { return humidity; }
    public double getSoilMoisture() { return soilMoisture; }
    public Timestamp getTimestamp() { return timestamp; }
}
