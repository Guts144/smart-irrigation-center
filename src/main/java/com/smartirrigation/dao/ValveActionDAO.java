package com.smartirrigation.dao;

import com.smartirrigation.db.DatabaseManager;
import com.smartirrigation.model.ValveAction;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ValveActionDAO {

    public void logAction(int userId, String action) {
        String sql = "INSERT INTO valve_history(user_id, action) VALUES(?,?)";

        try (Connection conn = DatabaseManager.connect();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.setString(2, action);
            pstmt.executeUpdate();
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }

    public List<ValveAction> getUserHistory(int userId) {
        String sql = "SELECT * FROM valve_history WHERE user_id = ? ORDER BY timestamp DESC";
        List<ValveAction> actions = new ArrayList<>();

        try (Connection conn = DatabaseManager.connect();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                actions.add(new ValveAction(
                        rs.getInt("id"),
                        rs.getInt("user_id"),
                        rs.getString("action"),
                        rs.getTimestamp("timestamp")
                ));
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return actions;
    }
    
    public int getActionCount(int userId) {
        String sql = "SELECT COUNT(*) FROM valve_history WHERE user_id = ?";
        try (Connection conn = DatabaseManager.connect();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return 0;
    }

    public List<ValveAction> getAllHistory() {
        String sql = "SELECT * FROM valve_history ORDER BY timestamp DESC";
        List<ValveAction> actions = new ArrayList<>();

        try (Connection conn = DatabaseManager.connect();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                actions.add(new ValveAction(
                        rs.getInt("id"),
                        rs.getInt("user_id"),
                        rs.getString("action"),
                        rs.getTimestamp("timestamp")
                ));
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return actions;
    }
}
