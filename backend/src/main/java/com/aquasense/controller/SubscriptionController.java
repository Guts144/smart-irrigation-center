package com.aquasense.controller;

import com.aquasense.dto.UserResponse;
import com.aquasense.service.AuthService;
import com.aquasense.service.ProAccessService;
import com.aquasense.service.StripeService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/subscription")
@RequiredArgsConstructor
public class SubscriptionController {

    private final ProAccessService proAccessService;
    private final StripeService stripeService;

    @PostMapping("/checkout")
    public Map<String, String> checkout() {
        var user = proAccessService.currentUser();
        String url = stripeService.createCheckoutSession(user);
        return Map.of("checkoutUrl", url);
    }

    @PostMapping("/complete")
    public UserResponse complete(@RequestParam("session_id") String sessionId) {
        var user = proAccessService.currentUser();
        var updated = stripeService.completeCheckoutSession(user, sessionId);
        return AuthService.toResponse(updated);
    }
}
