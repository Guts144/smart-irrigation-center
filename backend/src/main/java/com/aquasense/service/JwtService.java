package com.aquasense.service;

import com.aquasense.config.AquaSenseProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    private final SecretKey key;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtService(AquaSenseProperties properties) {
        this.key = Keys.hmacShaKeyFor(properties.jwt().secret().getBytes(StandardCharsets.UTF_8));
        this.accessExpirationMs = properties.jwt().accessTokenExpirationMs();
        this.refreshExpirationMs = properties.jwt().refreshTokenExpirationMs();
    }

    public String generateAccessToken(String email, String role) {
        return buildToken(email, role, accessExpirationMs, "access");
    }

    public String generateRefreshToken(String email, String role) {
        return buildToken(email, role, refreshExpirationMs, "refresh");
    }

    private String buildToken(String email, String role, long expirationMs, String type) {
        Date now = new Date();
        return Jwts.builder()
                .subject(email)
                .claim("role", role)
                .claim("type", type)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expirationMs))
                .signWith(key)
                .compact();
    }

    public Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public boolean isAccessToken(Claims claims) {
        return "access".equals(claims.get("type", String.class));
    }

    public boolean isRefreshToken(Claims claims) {
        return "refresh".equals(claims.get("type", String.class));
    }

    public long accessTokenMaxAgeSeconds() {
        return accessExpirationMs / 1000;
    }

    public long refreshTokenMaxAgeSeconds() {
        return refreshExpirationMs / 1000;
    }
}
