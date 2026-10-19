package com.aquasense.tracking.service;

import com.aquasense.entity.User;
import com.aquasense.repository.UserRepository;
import com.aquasense.tracking.dto.LocationUpdateRequest;
import com.aquasense.tracking.dto.StartTrackingRequest;
import com.aquasense.tracking.dto.StartTrackingResponse;
import com.aquasense.tracking.dto.TrackingInfoResponse;
import com.aquasense.tracking.entity.TrackingLocation;
import com.aquasense.tracking.entity.TrackingSession;
import com.aquasense.tracking.entity.TrackingStatus;
import com.aquasense.tracking.repository.TrackingLocationRepository;
import com.aquasense.tracking.repository.TrackingSessionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TrackingService {

        private final TrackingSessionRepository sessionRepository;
        private final TrackingLocationRepository locationRepository;
        private final UserRepository userRepository;
        private final SimpMessagingTemplate messagingTemplate;

        @Transactional
        public StartTrackingResponse startTracking(StartTrackingRequest request) {
                TrackingSession session = TrackingSession.builder()
                                .customerId(request.getCustomerId())
                                .technicianName(request.getTechnicianName())
                                .destinationLatitude(request.getDestinationLatitude())
                                .destinationLongitude(request.getDestinationLongitude())
                                .status(TrackingStatus.ACTIVE)
                                .trackingToken(UUID.randomUUID())
                                .startedAt(Instant.now())
                                .build();

                session = sessionRepository.save(session);
                return new StartTrackingResponse(session.getId(), session.getTrackingToken());
        }

        @Transactional
        public void updateLocation(LocationUpdateRequest request) {
                TrackingSession session = sessionRepository.findByTrackingToken(request.getTrackingToken())
                                .orElseThrow(() -> new IllegalArgumentException("Invalid tracking token"));

                if (session.getStatus() != TrackingStatus.ACTIVE) {
                        throw new IllegalStateException("Session is not ACTIVE");
                }

                TrackingLocation location = TrackingLocation.builder()
                                .trackingSessionId(session.getId())
                                .latitude(request.getLatitude())
                                .longitude(request.getLongitude())
                                .accuracy(request.getAccuracy())
                                .speed(request.getSpeed())
                                .timestamp(request.getTimestamp() != null ? request.getTimestamp() : Instant.now())
                                .build();

                locationRepository.save(location);

                // Broadcast to websocket
                TrackingInfoResponse update = buildInfoResponse(session, location);
                messagingTemplate.convertAndSend("/topic/tracking/" + session.getId(), update);
        }

        @Transactional
        public void markArrived(Long sessionId) {
                TrackingSession session = sessionRepository.findById(sessionId)
                                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

                session.setStatus(TrackingStatus.ARRIVED);
                session.setEndedAt(Instant.now());
                sessionRepository.save(session);

                TrackingLocation lastLocation = locationRepository
                                .findFirstByTrackingSessionIdOrderByTimestampDesc(session.getId())
                                .orElse(null);

                TrackingInfoResponse update = buildInfoResponse(session, lastLocation);
                messagingTemplate.convertAndSend("/topic/tracking/" + session.getId(), update);
        }

        @Transactional
        public void markArrivedByToken(UUID trackingToken) {
                TrackingSession session = sessionRepository.findByTrackingToken(trackingToken)
                                .orElseThrow(() -> new IllegalArgumentException("Invalid tracking token"));

                session.setStatus(TrackingStatus.ARRIVED);
                session.setEndedAt(Instant.now());
                sessionRepository.save(session);

                TrackingLocation lastLocation = locationRepository
                                .findFirstByTrackingSessionIdOrderByTimestampDesc(session.getId())
                                .orElse(null);

                TrackingInfoResponse update = buildInfoResponse(session, lastLocation);
                messagingTemplate.convertAndSend("/topic/tracking/" + session.getId(), update);
        }

        @Transactional(readOnly = true)
        public java.util.Optional<TrackingInfoResponse> getActiveSessionForCurrentUser() {
                String email = SecurityContextHolder.getContext().getAuthentication().getName();
                User user = userRepository.findByEmail(email)
                                .orElseThrow(() -> new IllegalArgumentException("User not found"));

                if (!user.isPro()) {
                        throw new IllegalStateException("Pro subscription required");
                }

                var sessionOpt = sessionRepository
                                .findFirstByCustomerIdAndStatusOrderByStartedAtDesc(user.getId(), TrackingStatus.ACTIVE);

                if (sessionOpt.isEmpty()) {
                        sessionOpt = sessionRepository.findFirstByStatusOrderByStartedAtDesc(TrackingStatus.ACTIVE);
                }

                return sessionOpt.map(session -> {
                        TrackingLocation lastLocation = locationRepository
                                        .findFirstByTrackingSessionIdOrderByTimestampDesc(
                                                        session.getId())
                                        .orElse(null);
                        return buildInfoResponse(session, lastLocation);
                });
        }

        @Transactional(readOnly = true)
        public TrackingInfoResponse getTrackingInfo(Long sessionId) {
                String email = SecurityContextHolder.getContext().getAuthentication().getName();
                User user = userRepository.findByEmail(email)
                                .orElseThrow(() -> new IllegalArgumentException("User not found"));

                if (!user.isPro()) {
                        throw new IllegalStateException("Pro subscription required");
                }

                TrackingSession session = sessionRepository.findById(sessionId)
                                .orElseThrow(() -> new IllegalArgumentException("Session not found"));

                if (!session.getCustomerId().equals(user.getId()) && user.getRole() != com.aquasense.entity.UserRole.ADMIN) {
                        throw new IllegalStateException("Not authorized to view this tracking session");
                }

                TrackingLocation lastLocation = locationRepository
                                .findFirstByTrackingSessionIdOrderByTimestampDesc(session.getId())
                                .orElse(null);

                return buildInfoResponse(session, lastLocation);
        }

        private TrackingInfoResponse buildInfoResponse(TrackingSession session, TrackingLocation location) {
                Double distance = null;
                Instant estimatedArrival = null;
                if (location != null && session.getDestinationLatitude() != null
                                && session.getDestinationLongitude() != null) {

                        // Calculate simple distance in meters (haversine)
                        double lat1 = Math.toRadians(location.getLatitude());
                        double lon1 = Math.toRadians(location.getLongitude());
                        double lat2 = Math.toRadians(session.getDestinationLatitude());
                        double lon2 = Math.toRadians(session.getDestinationLongitude());

                        double dlon = lon2 - lon1;
                        double dlat = lat2 - lat1;
                        double a = Math.pow(Math.sin(dlat / 2), 2)
                                        + Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(dlon / 2), 2);
                        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                        double r = 6371000; // Radius of earth in meters
                        distance = r * c;

                        if (location.getSpeed() != null && location.getSpeed() > 0) {
                                long etaSeconds = (long) (distance / location.getSpeed());
                                estimatedArrival = location.getTimestamp().plusSeconds(etaSeconds);
                        }
                }

                return TrackingInfoResponse.builder()
                                .sessionId(session.getId())
                                .technicianName(session.getTechnicianName())
                                .status(session.getStatus())
                                .currentLatitude(location != null ? location.getLatitude() : null)
                                .currentLongitude(location != null ? location.getLongitude() : null)
                                .destinationLatitude(session.getDestinationLatitude())
                                .destinationLongitude(session.getDestinationLongitude())
                                .currentSpeed(location != null ? location.getSpeed() : null)
                                .distanceRemaining(distance)
                                .lastUpdate(location != null ? location.getTimestamp() : null)
                                .estimatedArrival(estimatedArrival)
                                .build();
        }
}
