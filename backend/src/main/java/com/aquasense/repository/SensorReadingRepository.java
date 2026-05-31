package com.aquasense.repository;

import com.aquasense.entity.SensorReading;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SensorReadingRepository extends JpaRepository<SensorReading, Long> {
    Page<SensorReading> findAllByOrderByRecordedAtDesc(Pageable pageable);
}
