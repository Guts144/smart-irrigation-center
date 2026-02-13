package com.smartirrigation.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class DatabaseManager {
    private static final String DB_URL = "jdbc:sqlite:smart_irrigation.db?busy_timeout=10000";

    public static Connection connect() {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(DB_URL);
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
        return conn;
    }

    public static void initializeDatabase() {
        String createUsersTable = "CREATE TABLE IF NOT EXISTS users ("
                + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                + "username TEXT NOT NULL UNIQUE,"
                + "password TEXT NOT NULL,"
                + "role TEXT NOT NULL"
                + ");";

        String createSensorDataTable = "CREATE TABLE IF NOT EXISTS sensor_data ("
                + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                + "temperature REAL,"
                + "humidity REAL,"
                + "soil_moisture REAL,"
                + "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP"
                + ");";

        String createValveHistoryTable = "CREATE TABLE IF NOT EXISTS valve_history ("
                + "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                + "user_id INTEGER,"
                + "action TEXT,"
                + "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,"
                + "FOREIGN KEY(user_id) REFERENCES users(id)"
                + ");";

        // Admin setup
        String insertDefaultAdmin = "INSERT OR IGNORE INTO users (username, password, role) VALUES ('admin', 'admin123', 'ADMIN');";

        try (Connection conn = connect();
                Statement stmt = conn.createStatement()) {
            stmt.execute(createUsersTable);
            stmt.execute(createSensorDataTable);
            stmt.execute(createValveHistoryTable);
            stmt.execute(insertDefaultAdmin);

            // Performance optimizations
            stmt.execute("PRAGMA journal_mode=WAL;");
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_sensor_timestamp ON sensor_data(timestamp);");
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_valve_timestamp ON valve_history(timestamp);");

            System.out.println("Database initialized.");
        } catch (SQLException e) {
            System.out.println(e.getMessage());
        }
    }
}
