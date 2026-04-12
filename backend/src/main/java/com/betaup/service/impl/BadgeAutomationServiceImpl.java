package com.betaup.service.impl;

import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.entity.Badge;
import com.betaup.entity.BadgeCriteriaType;
import com.betaup.entity.ClimbResult;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.Notification;
import com.betaup.entity.User;
import com.betaup.entity.UserBadge;
import com.betaup.repository.BadgeRepository;
import com.betaup.repository.CheckInRepository;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.CommentRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.NotificationRepository;
import com.betaup.repository.PostLikeRepository;
import com.betaup.repository.PostRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.repository.UserRepository;
import com.betaup.service.BadgeAutomationService;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class BadgeAutomationServiceImpl implements BadgeAutomationService {

    private final BadgeRepository badgeRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final ClimbLogRepository climbLogRepository;
    private final FeedbackRepository feedbackRepository;
    private final UserRepository userRepository;
    private final CheckInRepository checkInRepository;
    private final PostRepository postRepository;
    private final PostLikeRepository postLikeRepository;
    private final CommentRepository commentRepository;
    private final NotificationRepository notificationRepository;

    @Override
    @Transactional
    public List<BadgeProgressDto> evaluateUserBadges(User user) {
        List<Badge> badges = badgeRepository.findAllByOrderByThresholdAsc();
        return reconcileUserBadges(user, badges);
    }

    @Override
    public List<BadgeProgressDto> getProgressForUser(User user) {
        Long userId = requireUserId(user);
        List<UserBadge> earnedBadges = userBadgeRepository.findByUserIdOrderByAwardedAtDesc(userId);
        List<Badge> allBadges = badgeRepository.findAllByOrderByThresholdAsc();
        Map<Long, UserBadge> earnedBadgesByBadgeId = earnedBadges.stream()
            .collect(Collectors.toMap(ub -> ub.getBadge().getId(), Function.identity()));
        Map<BadgeCriteriaType, Integer> progressByCriteria = buildProgressByCriteria(user);

        return allBadges.stream().map(badge -> {
            UserBadge earnedBadge = earnedBadgesByBadgeId.get(badge.getId());
            return BadgeProgressDto.builder()
                .badgeId(badge.getId())
                .badgeKey(badge.getBadgeKey())
                .name(badge.getName())
                .description(badge.getDescription())
                .criteriaType(badge.getCriteriaType())
                .threshold(badge.getThreshold())
                .category(badge.getCategory())
                .currentValue(progressByCriteria.getOrDefault(badge.getCriteriaType(), 0))
                .earned(earnedBadge != null)
                .awardedAt(earnedBadge == null ? null : earnedBadge.getAwardedAt())
                .build();
        }).toList();
    }

    @Override
    @Transactional
    public void reconcileAllClimberBadges() {
        List<Badge> badges = badgeRepository.findAllByOrderByThresholdAsc();
        userRepository.findByRoleOrderByCreatedAtDesc(com.betaup.entity.UserRole.CLIMBER)
            .forEach(user -> reconcileUserBadges(user, badges));
    }

    // ── private ────────────────────────────────────────────────────────────────

    private List<BadgeProgressDto> reconcileUserBadges(User user, List<Badge> badges) {
        Long userId = requireUserId(user);
        Map<Long, UserBadge> existingBadges = userBadgeRepository.findByUserId(userId)
            .stream()
            .collect(Collectors.toMap(ub -> ub.getBadge().getId(), Function.identity()));
        Map<BadgeCriteriaType, Integer> progressByCriteria = buildProgressByCriteria(user);

        List<BadgeProgressDto> newlyUnlocked = new ArrayList<>();

        badges.forEach(badge -> {
            int currentValue = progressByCriteria.getOrDefault(badge.getCriteriaType(), 0);
            UserBadge awarded = existingBadges.get(badge.getId());
            if (currentValue >= badge.getThreshold() && awarded == null) {
                UserBadge newBadge = UserBadge.builder()
                    .user(user)
                    .badge(badge)
                    .awardedAt(LocalDateTime.now())
                    .build();
                userBadgeRepository.save(newBadge);

                // Create in-app notification
                notificationRepository.save(Notification.builder()
                    .recipient(user)
                    .type("BADGE")
                    .actorId(user.getId())
                    .actorName("BetaUp")
                    .referenceId(badge.getId())
                    .content("🏅 恭喜！你获得了徽章：" + badge.getName())
                    .isRead(false)
                    .build());

                newlyUnlocked.add(BadgeProgressDto.builder()
                    .badgeId(badge.getId())
                    .badgeKey(badge.getBadgeKey())
                    .name(badge.getName())
                    .description(badge.getDescription())
                    .criteriaType(badge.getCriteriaType())
                    .threshold(badge.getThreshold())
                    .category(badge.getCategory())
                    .currentValue(currentValue)
                    .earned(true)
                    .awardedAt(LocalDateTime.now())
                    .build());
            } else if (currentValue < badge.getThreshold() && awarded != null) {
                userBadgeRepository.delete(Objects.requireNonNull(awarded));
            }
        });

        return newlyUnlocked;
    }

    private Map<BadgeCriteriaType, Integer> buildProgressByCriteria(User user) {
        Long userId = requireUserId(user);
        Map<BadgeCriteriaType, Integer> map = new EnumMap<>(BadgeCriteriaType.class);
        map.put(BadgeCriteriaType.TOTAL_LOGS,
            Math.toIntExact(climbLogRepository.countByUserId(userId)));
        map.put(BadgeCriteriaType.COMPLETED_CLIMBS,
            Math.toIntExact(climbLogRepository.countByUserIdAndStatus(userId, ClimbStatus.COMPLETED))
                + Math.toIntExact(climbLogRepository.countByUserIdAndResult(userId, ClimbResult.SEND))
                + Math.toIntExact(climbLogRepository.countByUserIdAndResult(userId, ClimbResult.FLASH)));
        map.put(BadgeCriteriaType.FLASH_CLIMBS,
            Math.toIntExact(climbLogRepository.countByUserIdAndResult(userId, ClimbResult.FLASH)));
        map.put(BadgeCriteriaType.FEEDBACK_RECEIVED,
            Math.toIntExact(feedbackRepository.countByClimberId(userId)));
        map.put(BadgeCriteriaType.GYM_CHECKINS,
            Math.toIntExact(checkInRepository.countByUserId(userId)));
        map.put(BadgeCriteriaType.UNIQUE_GYMS,
            Math.toIntExact(checkInRepository.countDistinctGymsByUserId(userId)));
        map.put(BadgeCriteriaType.POSTS_CREATED,
            Math.toIntExact(postRepository.countByUserId(userId)));
        map.put(BadgeCriteriaType.LIKES_RECEIVED,
            Math.toIntExact(postLikeRepository.countByPostUserId(userId)));
        map.put(BadgeCriteriaType.COMMENTS_MADE,
            Math.toIntExact(commentRepository.countByUserId(userId)));
        return map;
    }

    private Long requireUserId(User user) {
        return Objects.requireNonNull(user.getId(), "user id must not be null");
    }
}
