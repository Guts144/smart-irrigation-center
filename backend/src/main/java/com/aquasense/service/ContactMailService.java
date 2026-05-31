package com.aquasense.service;

import com.aquasense.config.AquaSenseProperties;
import com.aquasense.dto.ContactRequest;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class ContactMailService {

    private final JavaMailSender mailSender;
    private final AquaSenseProperties properties;

    public void sendContactNotification(ContactRequest request) throws MessagingException {
        var mail = properties.mail();
        if (!mail.enabled()) {
            throw new IllegalStateException("Contact email is disabled (set aquasense.mail.enabled=true and configure SMTP)");
        }

        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

        helper.setTo(mail.to());
        helper.setFrom(mail.from());
        helper.setReplyTo(request.email());
        helper.setSubject(mail.subjectPrefix() + " Message from " + request.name());

        String body = """
                New contact form submission on AquaSense

                Name: %s
                Email: %s

                Message:
                %s
                """.formatted(request.name(), request.email(), request.message());

        helper.setText(body, false);

        mailSender.send(message);
        log.info("Contact form email sent to {}", mail.to());
    }
}
