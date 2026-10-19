package com.aquasense.tracking.repository;

import com.aquasense.tracking.entity.TrackingSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;
import com.aquasense.tracking.entity.TrackingStatus;

@Repository
public interface TrackingSessionRepository extends JpaRepository<TrackingSession, Long> {
    Optional<TrackingSession> findByTrackingToken(UUID trackingToken);

    Optional<TrackingSession> findFirstByCustomerIdAndStatusOrderByStartedAtDesc(Long customerId,
            TrackingStatus status);

    Optional<TrackingSession> findFirstByStatusOrderByStartedAtDesc(TrackingStatus status);
}
