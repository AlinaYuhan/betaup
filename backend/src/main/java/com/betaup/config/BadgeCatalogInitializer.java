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

            // ── Climbing Level LEVEL ──────────────────────────────────────────
            Badge.builder()
                .badgeKey("LEVEL_FIRST_SEND")
                .name("First Send")
                .description("Complete your first route!")
                .threshold(1).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),
            Badge.builder()
                .badgeKey("LEVEL_SEND_10")
                .name("Beginner Climber")
                .description("Complete 10 routes total.")
                .threshold(10).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),
            Badge.builder()
                .badgeKey("LEVEL_SEND_30")
                .name("Intermediate Climber")
                .description("Complete 30 routes — your skills are growing steadily!")
                .threshold(30).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),
            Badge.builder()
                .badgeKey("LEVEL_SEND_100")
                .name("Century Climber")
                .description("Complete 100 routes — you're a true climbing master!")
                .threshold(100).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),

            // ── Training Challenge CHALLENGE ──────────────────────────────────
            Badge.builder()
                .badgeKey("FIRST_LOG")
                .name("First Log")
                .description("Record your first climb log.")
                .threshold(1).criteriaType(BadgeCriteriaType.TOTAL_LOGS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("LOG_50")
                .name("Dedicated Logger")
                .description("Log 50 climbs total.")
                .threshold(50).criteriaType(BadgeCriteriaType.TOTAL_LOGS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("FIRST_FLASH")
                .name("First Flash")
                .description("Flash any route on your first attempt!")
                .threshold(1).criteriaType(BadgeCriteriaType.FLASH_CLIMBS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("FLASH_10")
                .name("Flash Master")
                .description("Flash 10 routes — sight reading pro!")
                .threshold(10).criteriaType(BadgeCriteriaType.FLASH_CLIMBS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("COACH_LOOP")
                .name("Coach Certified")
                .description("Receive 3 pieces of coach feedback — keep improving!")
                .threshold(3).criteriaType(BadgeCriteriaType.FEEDBACK_RECEIVED)
                .category("CHALLENGE").build(),

            // ── Explore VENUE ─────────────────────────────────────────────────
            Badge.builder()
                .badgeKey("FIRST_CHECKIN")
                .name("First Check-In")
                .description("Check in to a climbing gym for the first time!")
                .threshold(1).criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("CHECKIN_10")
                .name("Regular Climber")
                .description("Check in 10 times total.")
                .threshold(10).criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("CHECKIN_50")
                .name("Gym Rat")
                .description("Check in 50 times — you live at the wall!")
                .threshold(50).criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("EXPLORER_3")
                .name("City Explorer")
                .description("Visit 3 different climbing gyms.")
                .threshold(3).criteriaType(BadgeCriteriaType.UNIQUE_GYMS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("EXPLORER_10")
                .name("Wall Traveller")
                .description("Visit 10 different climbing gyms across the city!")
                .threshold(10).criteriaType(BadgeCriteriaType.UNIQUE_GYMS)
                .category("VENUE").build(),

            // ── Social SOCIAL ─────────────────────────────────────────────────
            Badge.builder()
                .badgeKey("FIRST_POST")
                .name("First Post")
                .description("Share your first post with the community!")
                .threshold(1).criteriaType(BadgeCriteriaType.POSTS_CREATED)
                .category("SOCIAL").build(),
            Badge.builder()
                .badgeKey("POST_10")
                .name("Community Active")
                .description("Publish 10 posts total.")
                .threshold(10).criteriaType(BadgeCriteriaType.POSTS_CREATED)
                .category("SOCIAL").build(),
            Badge.builder()
                .badgeKey("LIKED_10")
                .name("Popular Climber")
                .description("Receive 10 likes on your posts!")
                .threshold(10).criteriaType(BadgeCriteriaType.LIKES_RECEIVED)
                .category("SOCIAL").build(),
            Badge.builder()
                .badgeKey("COMMENT_10")
                .name("Engaged Commenter")
                .description("Leave 10 comments on others' posts.")
                .threshold(10).criteriaType(BadgeCriteriaType.COMMENTS_MADE)
                .category("SOCIAL").build()
        );

        defaults.forEach(def ->
            badgeRepository.findByBadgeKey(def.getBadgeKey()).ifPresentOrElse(
                existing -> {
                    existing.setName(def.getName());
                    existing.setDescription(def.getDescription());
                    badgeRepository.save(existing);
                },
                () -> badgeRepository.save(def)
            )
        );
    }
}
