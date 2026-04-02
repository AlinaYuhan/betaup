package com.betaup.config;

import com.betaup.entity.Badge;
import com.betaup.entity.BadgeCriteriaType;
import com.betaup.repository.BadgeRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class BadgeCatalogInitializer implements ApplicationRunner {

    private final BadgeRepository badgeRepository;

    @Override
    public void run(ApplicationArguments args) {
        List<Badge> defaults = List.of(
            Badge.builder()
                .badgeKey("FIRST_LOG")
                .name("First Log")
                .description("Record your first climb session.")
                .threshold(1)
                .criteriaType(BadgeCriteriaType.TOTAL_LOGS)
                .build(),
            Badge.builder()
                .badgeKey("LOG_5")
                .name("Five Sessions")
                .description("Log five climb sessions.")
                .threshold(5)
                .criteriaType(BadgeCriteriaType.TOTAL_LOGS)
                .build(),
            Badge.builder()
                .badgeKey("FIRST_SEND")
                .name("First Send")
                .description("Complete your first climb.")
                .threshold(1)
                .criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .build(),
            Badge.builder()
                .badgeKey("SEND_10")
                .name("Send Machine")
                .description("Complete ten climbs.")
                .threshold(10)
                .criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .build(),
            Badge.builder()
                .badgeKey("COACH_LOOP")
                .name("Coach Loop")
                .description("Receive three coach feedback entries.")
                .threshold(3)
                .criteriaType(BadgeCriteriaType.FEEDBACK_RECEIVED)
                .build()
        );

        defaults.stream()
            .filter(defaultBadge -> badgeRepository.findByBadgeKey(defaultBadge.getBadgeKey()).isEmpty())
            .forEach(badgeRepository::save);
    }
}
