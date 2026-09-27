package com.aquasense.service;

import com.aquasense.dto.AuthTokensResponse;
import com.aquasense.dto.LoginRequest;
import com.aquasense.dto.RegisterRequest;
import com.aquasense.dto.UserResponse;
import com.aquasense.entity.SubscriptionStatus;
import com.aquasense.entity.User;
import com.aquasense.entity.UserRole;
import com.aquasense.repository.UserRepository;
import com.aquasense.security.CookieNames;
import com.aquasense.security.CookieUtils;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public UserResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already registered");
        }
        User user = User.builder()
                .email(request.email().toLowerCase())
                .fullName(request.fullName())
                .passwordHash(passwordEncoder.encode(request.password()))
                .role(UserRole.USER)
                .subscriptionStatus(SubscriptionStatus.NONE)
                .build();
        userRepository.save(user);
        return toResponse(user);
    }

    public UserResponse login(LoginRequest request, HttpServletResponse response) {
        User user = authenticate(request);
        setTokenCookies(response, user);
        return toResponse(user);
    }

    public UserResponse refresh(HttpServletResponse response, String refreshToken) {
        User user = userFromRefreshToken(refreshToken);
        setTokenCookies(response, user);
        return toResponse(user);
    }

    /** Mobile login: tokens are returned in the body instead of cookies. */
    public AuthTokensResponse mobileLogin(LoginRequest request) {
        return issueTokens(authenticate(request));
    }

    public AuthTokensResponse mobileRefresh(String refreshToken) {
        return issueTokens(userFromRefreshToken(refreshToken));
    }

    private User authenticate(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email().toLowerCase(), request.password()));
        return userRepository.findByEmail(request.email().toLowerCase())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
    }

    private User userFromRefreshToken(String refreshToken) {
        try {
            var claims = jwtService.parseClaims(refreshToken);
            if (!jwtService.isRefreshToken(claims)) {
                throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
            }
            return userRepository.findByEmail(claims.getSubject())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
        }
    }

    private AuthTokensResponse issueTokens(User user) {
        return new AuthTokensResponse(
                toResponse(user),
                jwtService.generateAccessToken(user.getEmail(), user.getRole().name()),
                jwtService.generateRefreshToken(user.getEmail(), user.getRole().name()),
                jwtService.accessTokenMaxAgeSeconds());
    }

    public void logout(HttpServletResponse response) {
        CookieUtils.clearCookie(response, CookieNames.ACCESS_TOKEN);
        CookieUtils.clearCookie(response, CookieNames.REFRESH_TOKEN);
    }

    public UserResponse currentUser() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        return toResponse(user);
    }

    private void setTokenCookies(HttpServletResponse response, User user) {
        String access = jwtService.generateAccessToken(user.getEmail(), user.getRole().name());
        String refresh = jwtService.generateRefreshToken(user.getEmail(), user.getRole().name());
        CookieUtils.addCookie(response, CookieNames.ACCESS_TOKEN, access, jwtService.accessTokenMaxAgeSeconds(), true);
        CookieUtils.addCookie(response, CookieNames.REFRESH_TOKEN, refresh, jwtService.refreshTokenMaxAgeSeconds(), true);
    }

    public static UserResponse toResponse(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getRole().name(),
                user.getSubscriptionStatus().name(),
                user.isPro());
    }
}
