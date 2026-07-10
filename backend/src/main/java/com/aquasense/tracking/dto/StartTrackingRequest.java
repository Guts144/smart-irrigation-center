package com.aquasense.tracking.dto;

import lombok.Data;

@Data
public class StartTrackingRequest {
    private Long customerId;
    private String technicianName;
    private Double destinationLatitude;
    private Double destinationLongitude;
}
