package com.betaup.config;

import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbResult;
import com.betaup.entity.ClimbSession;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.Notification;
import com.betaup.entity.User;
import com.betaup.entity.UserBadge;
import com.betaup.entity.UserRole;
import com.betaup.repository.BadgeRepository;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.ClimbSessionRepository;
import com.betaup.repository.NotificationRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.repository.UserRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@Order(3)   // after AdminAccountInitializer(1) and BadgeCatalogInitializer(2)
@RequiredArgsConstructor
public class DemoAccountInitializer implements ApplicationRunner {

    private static final String DEMO_EMAIL    = "cpt208";
    private static final String DEMO_NAME     = "cpt208";
    private static final String DEMO_PASSWORD = "cpt208";

    // Real gym names from GymDataInitializer
    private static final String GYM_XJTLU  = "西交利物浦大学攀岩馆";
    private static final String GYM_LCZ    = "刘常忠攀岩馆(独墅湖店)";

    private final UserRepository          userRepository;
    private final PasswordEncoder         passwordEncoder;
    private final ClimbSessionRepository  climbSessionRepository;
    private final ClimbLogRepository      climbLogRepository;
    private final UserBadgeRepository     userBadgeRepository;
    private final BadgeRepository         badgeRepository;
    private final NotificationRepository  notificationRepository;

    @Override
    public void run(ApplicationArguments args) {
        if (userRepository.existsByEmailIgnoreCase(DEMO_EMAIL)) {
            log.debug("[Demo] Account already exists, skipping seed.");
            return;
        }

        // ── 1. Create demo user ───────────────────────────────────────────
        User demo = userRepository.save(User.builder()
                .name(DEMO_NAME)
                .email(DEMO_EMAIL)
                .passwordHash(passwordEncoder.encode(DEMO_PASSWORD))
                .role(UserRole.CLIMBER)
                .city("苏州")
                .bio("V4 bouldering enthusiast · 苏州室内抱石 · logging every session 🧗")
                .totalClimbLogs(16)
                .build());

        LocalDate today = LocalDate.now();

        // ── 2. Sessions + logs ────────────────────────────────────────────
        long s1 = session(demo, today.minusDays(30), GYM_XJTLU, 110);
        log(demo, s1, "Overhang Intro",   "V3", today.minusDays(30), GYM_XJTLU, ClimbStatus.COMPLETED, ClimbResult.FLASH,   1);
        log(demo, s1, "Slab Corner",      "V3", today.minusDays(30), GYM_XJTLU, ClimbStatus.COMPLETED, ClimbResult.SEND,    2);

        long s2 = session(demo, today.minusDays(26), GYM_XJTLU, 95);
        log(demo, s2, "Crimpy Traverse",  "V4", today.minusDays(26), GYM_XJTLU, ClimbStatus.COMPLETED, ClimbResult.SEND,    3);

        long s3 = session(demo, today.minusDays(23), GYM_LCZ, 120);
        log(demo, s3, "Pocket Wall",      "V3", today.minusDays(23), GYM_LCZ,   ClimbStatus.COMPLETED, ClimbResult.FLASH,   1);
        log(demo, s3, "Dynamic Reach",    "V4", today.minusDays(23), GYM_LCZ,   ClimbStatus.COMPLETED, ClimbResult.SEND,    4);

        long s4 = session(demo, today.minusDays(20), GYM_LCZ, 130);
        log(demo, s4, "Compression Block","V4", today.minusDays(20), GYM_LCZ,   ClimbStatus.ATTEMPTED, ClimbResult.ATTEMPT, 5);
        log(demo, s4, "Pinch Series",     "V5", today.minusDays(20), GYM_LCZ,   ClimbStatus.ATTEMPTED, ClimbResult.ATTEMPT, 3);

        long s5 = session(demo, today.minusDays(16), GYM_XJTLU, 100);
        log(demo, s5, "Mantle Shelf",     "V3", today.minusDays(16), GYM_XJTLU, ClimbStatus.COMPLETED, ClimbResult.SEND,    2);
        log(demo, s5, "Heel Hook Corner", "V4", today.minusDays(16), GYM_XJTLU, ClimbStatus.COMPLETED, ClimbResult.FLASH,   1);

        long s6 = session(demo, today.minusDays(12), GYM_LCZ, 150);
        log(demo, s6, "Roof Problem",     "V5", today.minusDays(12), GYM_LCZ,   ClimbStatus.ATTEMPTED, ClimbResult.ATTEMPT, 6);
        log(demo, s6, "Balance Slab",     "V3", today.minusDays(12), GYM_LCZ,   ClimbStatus.COMPLETED, ClimbResult.SEND,    1);

        long s7 = session(demo, today.minusDays(7), GYM_XJTLU, 115);
        log(demo, s7, "Power Endurance",  "V4", today.minusDays(7),  GYM_XJTLU, ClimbStatus.COMPLETED, ClimbResult.SEND,    3);
        log(demo, s7, "Technical Crimp",  "V5", today.minusDays(7),  GYM_XJTLU, ClimbStatus.COMPLETED, ClimbResult.SEND,    7);

        long s8 = session(demo, today.minusDays(2), GYM_LCZ, 90);
        log(demo, s8, "Coordination Move","V4", today.minusDays(2),  GYM_LCZ,   ClimbStatus.COMPLETED, ClimbResult.FLASH,   1);
        log(demo, s8, "Project Warmup",   "V3", today.minusDays(2),  GYM_LCZ,   ClimbStatus.COMPLETED, ClimbResult.SEND,    2);

        // ── 3. Award badges + create notifications ─────────────────────────
        List<String> badgeKeys = List.of("FIRST_LOG", "LEVEL_FIRST_SEND", "LEVEL_SEND_10", "FIRST_FLASH");
        for (String key : badgeKeys) {
            awardBadgeWithNotification(demo, key);
        }

        log.info("[Demo] Seeded demo account '{}' with 8 sessions, 16 logs, {} badge notifications.", DEMO_EMAIL, badgeKeys.size());
    }

    private long session(User user, LocalDate date, String venue, int durationMinutes) {
        LocalDateTime start = date.atTime(14, 0);
        ClimbSession s = climbSessionRepository.save(ClimbSession.builder()
                .user(user)
                .startTime(start)
                .endTime(start.plusMinutes(durationMinutes))
                .venue(venue)
                .build());
        return s.getId();
    }

    private void log(User user, long sessionId, String routeName, String difficulty,
                     LocalDate date, String venue, ClimbStatus status, ClimbResult result, int attempts) {
        climbLogRepository.save(ClimbLog.builder()
                .user(user)
                .sessionId(sessionId)
                .routeName(routeName)
                .difficulty(difficulty)
                .date(date)
                .venue(venue)
                .status(status)
                .result(result)
                .attempts(attempts)
                .build());
    }

    private void awardBadgeWithNotification(User user, String badgeKey) {
        badgeRepository.findByBadgeKey(badgeKey).ifPresent(badge -> {
            if (userBadgeRepository.existsByUserIdAndBadgeId(user.getId(), badge.getId())) return;

            userBadgeRepository.save(UserBadge.builder()
                    .user(user)
                    .badge(badge)
                    .build());

            notificationRepository.save(Notification.builder()
                    .recipient(user)
                    .type("BADGE")
                    .actorId(user.getId())
                    .actorName("BetaUp")
                    .referenceId(badge.getId())
                    .content("🏅 You've earned the \"" + badge.getName() + "\" badge! Keep climbing!")
                    .build());
        });
    }
}
