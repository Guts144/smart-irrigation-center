package com.aquasense.service;

import com.aquasense.dto.SensorReadingDto;
import com.aquasense.entity.SensorReading;
import com.aquasense.repository.SensorReadingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class SensorService {

    private final SensorReadingRepository sensorReadingRepository;

    public SensorReading saveReading(double temperature, double humidity, double soilMoisture) {
        SensorReading reading = SensorReading.builder()
                .temperature(temperature)
                .humidity(humidity)
                .soilMoisture(soilMoisture)
                .build();
        return sensorReadingRepository.save(reading);
    }

    public Page<SensorReadingDto> getRecentReadings(int page, int size) {
        return sensorReadingRepository.findAllByOrderByRecordedAtDesc(PageRequest.of(page, size))
                .map(this::toDto);
    }

    public SensorReadingDto toDto(SensorReading reading) {
        return new SensorReadingDto(
                reading.getId(),
                reading.getTemperature(),
                reading.getHumidity(),
                reading.getSoilMoisture(),
                reading.getRecordedAt());
    }
}
