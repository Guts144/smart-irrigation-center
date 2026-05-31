package com.aquasense.config;

import com.aquasense.entity.SubscriptionStatus;
import com.aquasense.entity.User;
import com.aquasense.entity.UserRole;
import com.aquasense.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Bean
    CommandLineRunner seedAdmin() {
        return args -> {
            if (!userRepository.existsByEmail("admin@aquasense.io")) {
                userRepository.save(User.builder()
                        .email("admin@aquasense.io")
                        .fullName("AquaSense Admin")
                        .passwordHash(passwordEncoder.encode("admin123"))
                        .role(UserRole.ADMIN)
                        .subscriptionStatus(SubscriptionStatus.ACTIVE)
                        .build());
            }
        };
    }
}
