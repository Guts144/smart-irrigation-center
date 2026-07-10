package com.aquasense.tracking.controller;

import com.aquasense.tracking.dto.LocationUpdateRequest;
import com.aquasense.tracking.dto.StartTrackingRequest;
import com.aquasense.tracking.dto.StartTrackingResponse;
import com.aquasense.tracking.dto.TrackingInfoResponse;
import com.aquasense.tracking.service.TrackingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;
import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping("/api/tracking")
@RequiredArgsConstructor
@Slf4j
public class TrackingController {

    private final TrackingService trackingService;

    // Could be protected by JWT (admin/tech creating it)
    @PostMapping("/start")
    public ResponseEntity<StartTrackingResponse> startTracking(@RequestBody StartTrackingRequest request) {
        return ResponseEntity.ok(trackingService.startTracking(request));
    }

    // Unprotected, needs trackingToken
    @PostMapping("/location")
    public ResponseEntity<Void> updateLocation(@RequestBody LocationUpdateRequest request) {
        log.info("Received location update: {}", request);
        trackingService.updateLocation(request);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/active")
    public ResponseEntity<TrackingInfoResponse> getActiveSession() {
        return trackingService.getActiveSessionForCurrentUser()
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }

    // Protected by JWT + checks Pro
    @GetMapping("/{sessionId}")
    public ResponseEntity<TrackingInfoResponse> getTrackingInfo(@PathVariable("sessionId") Long sessionId) {
        return ResponseEntity.ok(trackingService.getTrackingInfo(sessionId));
    }

    // The user requested: POST /api/tracking/{sessionId}/arrived
    // If it's the technician, maybe it needs token?
    // The instructions say: "The technician GPS endpoint must not require a JWT
    // because it will be called from an Apple Shortcut. Authentication must rely on
    // the generated trackingToken (UUID)."
    // And "Implement: POST /api/tracking/{sessionId}/arrived ... Changes status to
    // ARRIVED"
    @PostMapping("/{sessionId}/arrived")
    public ResponseEntity<Void> arrived(@PathVariable("sessionId") Long sessionId,
            @RequestParam(value = "token", required = false) UUID token) {
        if (token != null) {
            trackingService.markArrivedByToken(token);
        } else {
            trackingService.markArrived(sessionId);
        }
        return ResponseEntity.ok().build();
    }
}
