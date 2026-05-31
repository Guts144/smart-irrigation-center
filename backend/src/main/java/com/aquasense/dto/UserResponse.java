package com.aquasense.dto;

public record UserResponse(
        Long id,
        String email,
        String fullName,
        String role,
        String subscriptionStatus,
        boolean pro) {}
