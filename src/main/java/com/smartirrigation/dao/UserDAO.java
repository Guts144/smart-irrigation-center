package com.smartirrigation.dao;

import com.smartirrigation.db.DatabaseManager;
import com.smartirrigation.model.User;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class UserDAO {

    public boolean registerUser(String username, String password) {
        return registerUser(username, password, "USER");
    }

    public boolean registerUser(String username, String password, String role) {
        String sql = "INSERT INTO users(username, password, role) VALUES(?, ?, ?)";

        try (Connection conn = DatabaseManager.connect();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            pstmt.setString(2, password); // In production, hash this!
            pstmt.setString(3, role);
            pstmt.executeUpdate();
            return true;
        } catch (SQLException e) {
            System.out.println(e.getMessage());
            return false;
        }
    }

    public User loginUser(String username, String password) {
        String sql = "SELECT * FROM users WHERE username = ? AND password = ?";

        try (Connection conn = DatabaseManager.connect();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setString(1, username);
            pstmt.setString(2, password);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                return new User(
                        rs.getInt("id"),
                        rs.getString("username"),
                        rs.getString("password"),
                        rs.getString("role"));
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return null;
    }
}
