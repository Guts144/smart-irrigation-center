package com.smartirrigation;

import com.smartirrigation.dao.SensorDataDAO;
import com.smartirrigation.dao.UserDAO;
import com.smartirrigation.dao.ValveActionDAO;
import com.smartirrigation.db.DatabaseManager;
import com.smartirrigation.model.User;
import com.smartirrigation.service.MqttService;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

import java.io.File;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class SystemIntegrationTest {

    private static final UserDAO userDAO = new UserDAO();
    private static final SensorDataDAO sensorDAO = new SensorDataDAO();
    private static final ValveActionDAO valveDAO = new ValveActionDAO();
    private static final MqttService mqttService = MqttService.getInstance();

    @BeforeAll
    static void setup() {
        // Initialize JavaFX Toolkit for Platform.runLater
        try {
            javafx.application.Platform.startup(() -> {
            });
        } catch (IllegalStateException e) {
            // Toolkit already initialized
        }

        // Initialize DB
        DatabaseManager.initializeDatabase();
    }

    @Test
    @Order(1)
    void testDatabaseInitialization() {
        File dbFile = new File("smart_irrigation.db");
        assertTrue(dbFile.exists(), "Database file should exist");
    }

    @Test
    @Order(2)
    void testUserRegistrationAndLogin() {
        String testUser = "testUser_" + System.currentTimeMillis();
        assertTrue(userDAO.registerUser(testUser, "password123"), "User registration should succeed");

        User user = userDAO.loginUser(testUser, "password123");
        assertNotNull(user, "User login should return a user object");
        assertEquals(testUser, user.getUsername());
        assertEquals("USER", user.getRole());
    }

    @Test
    @Order(3)
    void testMqttConnection() throws InterruptedException {
        CountDownLatch latch = new CountDownLatch(1);
        mqttService.setOnConnectionStatusChanged(isConnected -> {
            if (isConnected)
                latch.countDown();
        });

        mqttService.connect();
        boolean connected = latch.await(10, TimeUnit.SECONDS);
        assertTrue(connected, "MQTT should connect within 10 seconds");
    }

    @Test
    @Order(4)
    void testSensorDataPersistence() {
        // Indirect test: Insert manually and retrieve
        sensorDAO.insertReading(25.5, 60.0, 45.0);
        var readings = sensorDAO.getRecentReadings(1);
        assertFalse(readings.isEmpty(), "Should retrieve recent readings");
        assertEquals(25.5, readings.get(0).getTemperature(), 0.1);
    }

    @Test
    @Order(5)
    void testValveActionLogging() {
        // Create user first if needed, or use ID 1 (admin)
        valveDAO.logAction(1, "OPEN");
        var history = valveDAO.getUserHistory(1);
        assertFalse(history.isEmpty());
        assertEquals("OPEN", history.get(0).getAction());
    }

    @AfterAll
    static void tearDown() {
        mqttService.disconnect();
    }
}
