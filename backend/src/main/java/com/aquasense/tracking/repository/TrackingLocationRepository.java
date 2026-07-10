package com.aquasense.tracking.repository;

import com.aquasense.tracking.entity.TrackingLocation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TrackingLocationRepository extends JpaRepository<TrackingLocation, Long> {
    List<TrackingLocation> findByTrackingSessionIdOrderByTimestampAsc(Long trackingSessionId);

    Optional<TrackingLocation> findFirstByTrackingSessionIdOrderByTimestampDesc(Long trackingSessionId);
}
