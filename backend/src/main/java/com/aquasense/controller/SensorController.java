package com.aquasense.controller;

import com.aquasense.dto.SensorReadingDto;
import com.aquasense.service.MqttBridgeService;
import com.aquasense.service.ProAccessService;
import com.aquasense.service.SensorService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/pro")
@RequiredArgsConstructor
public class SensorController {

    private final ProAccessService proAccessService;
    private final SensorService sensorService;
    private final MqttBridgeService mqttBridgeService;

    @GetMapping("/sensors")
    public Page<SensorReadingDto> recentReadings(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) {
        proAccessService.requireProUser();
        return sensorService.getRecentReadings(page, size);
    }

    @GetMapping("/connection")
    public Map<String, Object> connectionStatus() {
        proAccessService.requireProUser();
        return Map.of("mqttConnected", mqttBridgeService.isConnected());
    }
}
