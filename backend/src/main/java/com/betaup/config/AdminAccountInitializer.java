package com.betaup.config;

import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@Order(1)   // run before badge / gym initializers
@RequiredArgsConstructor
public class AdminAccountInitializer implements ApplicationRunner {

    @Value("${app.admin.email:admin@betaup.com}")
    private String adminEmail;

    @Value("${app.admin.name:admin}")
    private String adminName;

    @Value("${app.admin.password:12345678}")
    private String adminPassword;

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(ApplicationArguments args) {
        if (userRepository.existsByEmailIgnoreCase(adminEmail)) {
            log.debug("[Admin] Account already exists, skipping seed.");
            return;
        }

        User admin = User.builder()
            .name(adminName)
            .email(adminEmail)
            .passwordHash(passwordEncoder.encode(adminPassword))
            .role(UserRole.ADMIN)
            .build();

        userRepository.save(admin);
        log.info("[Admin] Seeded admin account: {}", adminEmail);
    }
}
