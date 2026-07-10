package com.aquasense.tracking.dto;

import com.aquasense.tracking.entity.TrackingStatus;
import lombok.Builder;
import lombok.Data;

import java.time.Instant;

@Data
@Builder
public class TrackingInfoResponse {
    private Long sessionId;
    private String technicianName;
    private TrackingStatus status;
    private Double currentLatitude;
    private Double currentLongitude;
    private Double destinationLatitude;
    private Double destinationLongitude;
    private Double currentSpeed;
    private Double distanceRemaining;
    private Instant lastUpdate;
    private Instant estimatedArrival;
}
