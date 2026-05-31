package com.aquasense.dto;

import java.time.Instant;

public record SensorReadingDto(
        Long id,
        double temperature,
        double humidity,
        double soilMoisture,
        Instant recordedAt) {}
