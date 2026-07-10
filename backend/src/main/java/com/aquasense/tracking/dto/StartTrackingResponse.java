package com.aquasense.tracking.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class StartTrackingResponse {
    private Long sessionId;
    private UUID trackingToken;
}
