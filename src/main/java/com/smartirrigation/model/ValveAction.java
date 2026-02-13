package com.smartirrigation.model;

import java.sql.Timestamp;

public class ValveAction {
    private int id;
    private int userId;
    private String action; // "OPEN" or "CLOSE"
    private Timestamp timestamp;

    public ValveAction(int userId, String action) {
        this.userId = userId;
        this.action = action;
    }

    public ValveAction(int id, int userId, String action, Timestamp timestamp) {
        this.id = id;
        this.userId = userId;
        this.action = action;
        this.timestamp = timestamp;
    }

    public int getId() { return id; }
    public int getUserId() { return userId; }
    public String getAction() { return action; }
    public Timestamp getTimestamp() { return timestamp; }
}
