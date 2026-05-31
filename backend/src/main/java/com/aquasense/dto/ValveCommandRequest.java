package com.aquasense.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record ValveCommandRequest(
        @NotBlank @Pattern(regexp = "OPEN|CLOSE") String action) {}
