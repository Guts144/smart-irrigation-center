package com.aquasense.tracking.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "tracking_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TrackingSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, updatable = false)
    private UUID trackingToken;

    @Column(nullable = false)
    private Long customerId;

    @Column(nullable = false)
    private String technicianName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TrackingStatus status;

    @Column(nullable = false)
    private Instant startedAt;

    private Instant endedAt;

    private Double destinationLatitude;
    private Double destinationLongitude;

    @PrePersist
    protected void onCreate() {
        if (trackingToken == null) {
            trackingToken = UUID.randomUUID();
        }
        if (startedAt == null) {
            startedAt = Instant.now();
        }
        if (status == null) {
            status = TrackingStatus.ACTIVE;
        }
    }
}
