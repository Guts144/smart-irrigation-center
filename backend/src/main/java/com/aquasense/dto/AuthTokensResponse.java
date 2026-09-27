package com.aquasense.dto;

public record AuthTokensResponse(
        UserResponse user,
        String accessToken,
        String refreshToken,
        long expiresIn) {}
