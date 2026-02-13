package com.smartirrigation.dao;

import com.smartirrigation.db.DatabaseManager;
import com.smartirrigation.model.SensorData;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SensorDataDAO {

    public void insertReading(double temp, double humidity, double moisture) {
        String sql = "INSERT INTO sensor_data(temperature, humidity, soil_moisture) VALUES(?,?,?)";

        try (Connection conn = DatabaseManager.connect();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setDouble(1, temp);
            pstmt.setDouble(2, humidity);
            pstmt.setDouble(3, moisture);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    public List<SensorData> getRecentReadings(int limit) {
        String sql = "SELECT * FROM sensor_data ORDER BY timestamp DESC LIMIT ?";
        List<SensorData> readings = new ArrayList<>();

        try (Connection conn = DatabaseManager.connect();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, limit);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                readings.add(new SensorData(
                        rs.getInt("id"),
                        rs.getDouble("temperature"),
                        rs.getDouble("humidity"),
                        rs.getDouble("soil_moisture"),
                        rs.getTimestamp("timestamp")
                ));
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return readings;
    }
}
