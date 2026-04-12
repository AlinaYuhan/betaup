package com.betaup.config;

import com.betaup.entity.Badge;
import com.betaup.entity.BadgeCriteriaType;
import com.betaup.repository.BadgeRepository;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
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

            // ── 攀岩等级 LEVEL ────────────────────────────────────────────────
            Badge.builder()
                .badgeKey("LEVEL_FIRST_SEND")
                .name("首次完攀")
                .description("完成你的第一条路线！")
                .threshold(1).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),
            Badge.builder()
                .badgeKey("LEVEL_SEND_10")
                .name("初级攀岩者")
                .description("累计完成10条路线。")
                .threshold(10).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),
            Badge.builder()
                .badgeKey("LEVEL_SEND_30")
                .name("进阶攀岩者")
                .description("累计完成30条路线，你的技术在稳步提升！")
                .threshold(30).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),
            Badge.builder()
                .badgeKey("LEVEL_SEND_100")
                .name("百条成就")
                .description("累计完成100条路线，你是真正的攀岩高手！")
                .threshold(100).criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
                .category("LEVEL").build(),

            // ── 训练挑战 CHALLENGE ────────────────────────────────────────────
            Badge.builder()
                .badgeKey("FIRST_LOG")
                .name("初次记录")
                .description("记录你的第一条攀岩日志。")
                .threshold(1).criteriaType(BadgeCriteriaType.TOTAL_LOGS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("LOG_50")
                .name("勤奋记录者")
                .description("累计记录50条攀岩日志。")
                .threshold(50).criteriaType(BadgeCriteriaType.TOTAL_LOGS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("FIRST_FLASH")
                .name("初次闪耀")
                .description("首次 Flash 任意路线！")
                .threshold(1).criteriaType(BadgeCriteriaType.FLASH_CLIMBS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("FLASH_10")
                .name("闪电侠")
                .description("累计 Flash 10条路线，眼到手到！")
                .threshold(10).criteriaType(BadgeCriteriaType.FLASH_CLIMBS)
                .category("CHALLENGE").build(),
            Badge.builder()
                .badgeKey("COACH_LOOP")
                .name("Coach 认证")
                .description("收到3条教练反馈，持续进步！")
                .threshold(3).criteriaType(BadgeCriteriaType.FEEDBACK_RECEIVED)
                .category("CHALLENGE").build(),

            // ── 探险打卡 VENUE ────────────────────────────────────────────────
            Badge.builder()
                .badgeKey("FIRST_CHECKIN")
                .name("初次到馆")
                .description("完成你的第一次岩馆打卡！")
                .threshold(1).criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("CHECKIN_10")
                .name("攀岩达人")
                .description("累计打卡10次。")
                .threshold(10).criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("CHECKIN_50")
                .name("攀岩狂人")
                .description("累计打卡50次，你是真正的攀岩达人！")
                .threshold(50).criteriaType(BadgeCriteriaType.GYM_CHECKINS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("EXPLORER_3")
                .name("城市探索者")
                .description("探索3家不同的攀岩馆。")
                .threshold(3).criteriaType(BadgeCriteriaType.UNIQUE_GYMS)
                .category("VENUE").build(),
            Badge.builder()
                .badgeKey("EXPLORER_10")
                .name("攀岩地图")
                .description("探索10家不同的攀岩馆，集齐全国地图！")
                .threshold(10).criteriaType(BadgeCriteriaType.UNIQUE_GYMS)
                .category("VENUE").build(),

            // ── 社交 SOCIAL ───────────────────────────────────────────────────
            Badge.builder()
                .badgeKey("FIRST_POST")
                .name("初次发声")
                .description("发布你的第一条动态！")
                .threshold(1).criteriaType(BadgeCriteriaType.POSTS_CREATED)
                .category("SOCIAL").build(),
            Badge.builder()
                .badgeKey("POST_10")
                .name("社区活跃者")
                .description("累计发布10条动态。")
                .threshold(10).criteriaType(BadgeCriteriaType.POSTS_CREATED)
                .category("SOCIAL").build(),
            Badge.builder()
                .badgeKey("LIKED_10")
                .name("人气攀岩者")
                .description("你的动态累计获得10个点赞！")
                .threshold(10).criteriaType(BadgeCriteriaType.LIKES_RECEIVED)
                .category("SOCIAL").build(),
            Badge.builder()
                .badgeKey("COMMENT_10")
                .name("热心评论员")
                .description("累计评论10次。")
                .threshold(10).criteriaType(BadgeCriteriaType.COMMENTS_MADE)
                .category("SOCIAL").build()
        );

        Set<String> existing = badgeRepository.findAll().stream()
            .map(Badge::getBadgeKey)
            .collect(Collectors.toSet());
        defaults.stream()
            .filter(b -> !existing.contains(b.getBadgeKey()))
            .forEach(badgeRepository::save);
    }
}
