package com.aquasense.service;

import com.aquasense.config.AquaSenseProperties;
import com.aquasense.entity.SubscriptionStatus;
import com.aquasense.entity.User;
import com.aquasense.repository.UserRepository;
import com.stripe.Stripe;
import com.stripe.exception.SignatureVerificationException;
import com.stripe.model.Event;
import com.stripe.model.checkout.Session;
import com.stripe.net.Webhook;
import com.stripe.param.checkout.SessionCreateParams;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Slf4j
@Service
@RequiredArgsConstructor
public class StripeService {

    private final AquaSenseProperties properties;
    private final UserRepository userRepository;

    @PostConstruct
    void init() {
        Stripe.apiKey = properties.stripe().apiKey();
        if (!isConfigured()) {
            log.warn("Stripe is not configured — set STRIPE_API_KEY and STRIPE_PRO_PRICE_ID to enable Pro checkout");
        }
    }

    public String createCheckoutSession(User user) {
        return createCheckoutSession(user, null);
    }

    public String createCheckoutSession(User user, String platform) {
        assertConfigured();
        boolean isMobile = "mobile".equalsIgnoreCase(platform);
        String successUrl = isMobile
                ? "aquasense://checkout/success?session_id={CHECKOUT_SESSION_ID}"
                : properties.stripe().successUrl();
        String cancelUrl = isMobile
                ? "aquasense://pricing?checkout=cancelled"
                : properties.stripe().cancelUrl();

        try {
            SessionCreateParams params = SessionCreateParams.builder()
                    .setMode(SessionCreateParams.Mode.SUBSCRIPTION)
                    .setSuccessUrl(successUrl)
                    .setCancelUrl(cancelUrl)
                    .setCustomerEmail(user.getEmail())
                    .addLineItem(SessionCreateParams.LineItem.builder()
                            .setPrice(properties.stripe().proPriceId())
                            .setQuantity(1L)
                            .build())
                    .putMetadata("userId", user.getId().toString())
                    .build();
            Session session = Session.create(params);
            if (session.getUrl() == null) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Stripe did not return a checkout URL");
            }
            return session.getUrl();
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            log.error("Stripe checkout failed: {}", e.getMessage());
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                    "Stripe checkout failed: " + e.getMessage());
        }
    }

    public User completeCheckoutSession(User user, String sessionId) {
        assertConfigured();
        try {
            Session session = Session.retrieve(sessionId);
            if (!"complete".equals(session.getStatus())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Checkout session is not complete");
            }
            String ownerId = session.getMetadata() != null ? session.getMetadata().get("userId") : null;
            if (ownerId == null || !ownerId.equals(user.getId().toString())) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Checkout session does not belong to this account");
            }
            return activateProFromSession(user, session);
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            log.error("Failed to complete checkout: {}", e.getMessage());
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Could not verify payment with Stripe");
        }
    }

    public void handleWebhook(String payload, String sigHeader) {
        Event event;
        try {
            event = Webhook.constructEvent(payload, sigHeader, properties.stripe().webhookSecret());
        } catch (SignatureVerificationException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid signature");
        }

        if ("checkout.session.completed".equals(event.getType())) {
            Session session = (Session) event.getDataObjectDeserializer().getObject().orElse(null);
            if (session != null && session.getMetadata() != null) {
                String userId = session.getMetadata().get("userId");
                userRepository.findById(Long.parseLong(userId)).ifPresent(user -> activateProFromSession(user, session));
            }
        }

        if ("customer.subscription.deleted".equals(event.getType())) {
            com.stripe.model.Subscription sub = (com.stripe.model.Subscription) event.getDataObjectDeserializer()
                    .getObject().orElse(null);
            if (sub != null) {
                userRepository.findByStripeCustomerId(sub.getCustomer()).ifPresent(user -> {
                    user.setSubscriptionStatus(SubscriptionStatus.CANCELED);
                    userRepository.save(user);
                });
            }
        }
    }

    private User activateProFromSession(User user, Session session) {
        user.setSubscriptionStatus(SubscriptionStatus.ACTIVE);
        user.setStripeCustomerId(session.getCustomer());
        user.setStripeSubscriptionId(session.getSubscription());
        return userRepository.save(user);
    }

    private boolean isConfigured() {
        var stripe = properties.stripe();
        return stripe.apiKey() != null && !stripe.apiKey().contains("placeholder")
                && stripe.proPriceId() != null && !stripe.proPriceId().contains("placeholder");
    }

    private void assertConfigured() {
        if (!isConfigured()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Stripe is not configured. Set STRIPE_API_KEY and STRIPE_PRO_PRICE_ID environment variables.");
        }
    }
}
