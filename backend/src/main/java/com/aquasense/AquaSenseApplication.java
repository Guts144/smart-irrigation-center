package com.aquasense;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

import com.aquasense.config.AquaSenseProperties;

@SpringBootApplication
@EnableConfigurationProperties(AquaSenseProperties.class)
public class AquaSenseApplication {

    public static void main(String[] args) {
        SpringApplication.run(AquaSenseApplication.class, args);
    }
}
