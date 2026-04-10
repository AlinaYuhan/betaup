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
                .build(),
            // Location badges (check-in count)
            Badge.builder()
                .badgeKey("FIRST_CHECKIN")
                .name("初次到馆")
                .description("完成你的第一次到馆打卡！")
                .threshold(1)
                .criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .build(),
            Badge.builder()
                .badgeKey("CHECKIN_10")
                .name("攀岩达人")
                .description("累计打卡10次。")
                .threshold(10)
                .criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .build(),
            Badge.builder()
                .badgeKey("CHECKIN_50")
                .name("攀岩狂人")
                .description("累计打卡50次，你是真正的攀岩达人！")
                .threshold(50)
                .criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .build(),
            // Collection badges (unique gyms)
            Badge.builder()
                .badgeKey("EXPLORER_3")
                .name("城市探索者")
                .description("探索3家不同的攀岩馆。")
                .threshold(3)
                .criteriaType(BadgeCriteriaType.UNIQUE_GYMS)
                .build(),
            Badge.builder()
                .badgeKey("EXPLORER_10")
                .name("攀岩地图")
                .description("探索10家不同的攀岩馆，集齐全国地图！")
                .threshold(10)
                .criteriaType(BadgeCriteriaType.UNIQUE_GYMS)
                .build(),
            // Social badges
            Badge.builder()
                .badgeKey("FIRST_POST")
                .name("初次发声")
                .description("发布你的第一条动态！")
                .threshold(1)
                .criteriaType(BadgeCriteriaType.POSTS_CREATED)
                .build(),
            Badge.builder()
                .badgeKey("POST_10")
                .name("社区活跃者")
                .description("累计发布10条动态。")
                .threshold(10)
                .criteriaType(BadgeCriteriaType.POSTS_CREATED)
                .build(),
            Badge.builder()
                .badgeKey("LIKED_10")
                .name("人气攀岩者")
                .description("你的动态累计获得10个点赞！")
                .threshold(10)
                .criteriaType(BadgeCriteriaType.LIKES_RECEIVED)
                .build(),
            Badge.builder()
                .badgeKey("COMMENT_10")
                .name("热心评论员")
                .description("累计评论10次。")
                .threshold(10)
                .criteriaType(BadgeCriteriaType.COMMENTS_MADE)
                .build()
        );

        defaults.stream()
            .filter(defaultBadge -> badgeRepository.findByBadgeKey(defaultBadge.getBadgeKey()).isEmpty())
            .forEach(badgeRepository::save);
    }
}
