package com.aquasense.controller;

import com.aquasense.dto.ValveCommandRequest;
import com.aquasense.entity.ValveCommand;
import com.aquasense.repository.ValveCommandRepository;
import com.aquasense.service.MqttBridgeService;
import com.aquasense.service.ProAccessService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/pro/valve")
@RequiredArgsConstructor
public class ValveController {

    private final ProAccessService proAccessService;
    private final MqttBridgeService mqttBridgeService;
    private final ValveCommandRepository valveCommandRepository;

    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    public void sendCommand(@Valid @RequestBody ValveCommandRequest request) {
        var user = proAccessService.requireProUser();
        if (!mqttBridgeService.isConnected()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE, "MQTT broker is disconnected");
        }
        mqttBridgeService.publishValveCommand(request.action());
        valveCommandRepository.save(ValveCommand.builder()
                .user(user)
                .action(request.action())
                .build());
    }
}
