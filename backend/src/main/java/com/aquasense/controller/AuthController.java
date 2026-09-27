package com.aquasense.controller;

import com.aquasense.dto.AuthTokensResponse;
import com.aquasense.dto.LoginRequest;
import com.aquasense.dto.RefreshTokenRequest;
import com.aquasense.dto.RegisterRequest;
import com.aquasense.dto.UserResponse;
import com.aquasense.security.CookieNames;
import com.aquasense.security.CookieUtils;
import com.aquasense.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public UserResponse register(@Valid @RequestBody RegisterRequest request) {
        return authService.register(request);
    }

    @PostMapping("/login")
    public UserResponse login(@Valid @RequestBody LoginRequest request, HttpServletResponse response) {
        return authService.login(request, response);
    }

    @PostMapping("/refresh")
    public UserResponse refresh(HttpServletRequest request, HttpServletResponse response) {
        String refreshToken = CookieUtils.getCookieValue(request, CookieNames.REFRESH_TOKEN)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(
                        org.springframework.http.HttpStatus.UNAUTHORIZED, "No refresh token"));
        return authService.refresh(response, refreshToken);
    }

    @PostMapping("/mobile/login")
    public AuthTokensResponse mobileLogin(@Valid @RequestBody LoginRequest request) {
        return authService.mobileLogin(request);
    }

    @PostMapping("/mobile/refresh")
    public AuthTokensResponse mobileRefresh(@Valid @RequestBody RefreshTokenRequest request) {
        return authService.mobileRefresh(request.refreshToken());
    }

    @PostMapping("/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(HttpServletResponse response) {
        authService.logout(response);
    }

    @GetMapping("/me")
    public UserResponse me() {
        return authService.currentUser();
    }
}
