package com.aquasense.service;

import com.aquasense.entity.User;
import com.aquasense.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
@RequiredArgsConstructor
public class ProAccessService {

    private final UserRepository userRepository;

    public User requireProUser() {
        User user = currentUser();
        if (!user.isPro() && user.getRole() != com.aquasense.entity.UserRole.ADMIN) {
            throw new ResponseStatusException(HttpStatus.PAYMENT_REQUIRED, "Pro subscription required");
        }
        return user;
    }

    public User currentUser() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED));
    }
}
