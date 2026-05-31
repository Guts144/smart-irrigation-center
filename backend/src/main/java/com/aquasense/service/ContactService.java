package com.aquasense.service;

import com.aquasense.dto.ContactRequest;
import com.aquasense.entity.ContactMessage;
import com.aquasense.repository.ContactMessageRepository;
import jakarta.mail.MessagingException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailAuthenticationException;
import org.springframework.mail.MailException;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Slf4j
@Service
@RequiredArgsConstructor
public class ContactService {

    private final ContactMessageRepository contactMessageRepository;
    private final ContactMailService contactMailService;

    public void submit(ContactRequest request) {
        contactMessageRepository.save(ContactMessage.builder()
                .name(request.name())
                .email(request.email())
                .message(request.message())
                .build());

        try {
            contactMailService.sendContactNotification(request);
        } catch (IllegalStateException ex) {
            log.error("Contact email not configured", ex);
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Email is not configured on the server.");
        } catch (MailAuthenticationException ex) {
            log.error("SMTP authentication failed", ex);
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Email server authentication failed. Use a Gmail App Password in MAIL_PASSWORD (not your normal password).");
        } catch (MailException | MessagingException ex) {
            log.error("Failed to send contact notification email", ex);
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE,
                    "Could not send your message. Please try again later.");
        }
    }
}
