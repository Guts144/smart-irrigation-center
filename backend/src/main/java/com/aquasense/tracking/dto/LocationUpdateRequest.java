package com.aquasense.tracking.dto;

import lombok.Data;
import java.time.Instant;
import java.util.UUID;

@Data
public class LocationUpdateRequest {
    private UUID trackingToken;
    private Double latitude;
    private Double longitude;
    private Double accuracy;
    private Double speed;
    private Instant timestamp;
}
