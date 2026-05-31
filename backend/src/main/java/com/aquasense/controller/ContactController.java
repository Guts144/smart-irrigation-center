package com.aquasense.controller;

import com.aquasense.dto.ContactRequest;
import com.aquasense.service.ContactService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    @PostMapping("/contact")
    @ResponseStatus(HttpStatus.CREATED)
    public void submit(@Valid @RequestBody ContactRequest request) {
        contactService.submit(request);
    }
}
