package com.betaup.service.impl;

import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.entity.Badge;
import com.betaup.entity.BadgeCriteriaType;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.User;
import com.betaup.entity.UserBadge;
import com.betaup.repository.BadgeRepository;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.repository.UserRepository;
import com.betaup.service.BadgeAutomationService;
import java.util.EnumMap;
import java.time.LocalDateTime;
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

    @Override
    @Transactional
    public void evaluateUserBadges(User user) {
        List<Badge> badges = badgeRepository.findAllByOrderByThresholdAsc();
        reconcileUserBadges(user, badges);
    }

    @Override
    public List<BadgeProgressDto> getProgressForUser(User user) {
        Long userId = requireUserId(user);
        List<UserBadge> earnedBadges = userBadgeRepository.findByUserIdOrderByAwardedAtDesc(userId);
        List<Badge> allBadges = badgeRepository.findAllByOrderByThresholdAsc();
        Map<Long, UserBadge> earnedBadgesByBadgeId = earnedBadges.stream()
            .collect(Collectors.toMap(userBadge -> userBadge.getBadge().getId(), Function.identity()));
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

    private void reconcileUserBadges(User user, List<Badge> badges) {
        Long userId = requireUserId(user);
        Map<Long, UserBadge> existingBadges = userBadgeRepository.findByUserId(userId)
            .stream()
            .collect(Collectors.toMap(userBadge -> userBadge.getBadge().getId(), Function.identity()));
        Map<BadgeCriteriaType, Integer> progressByCriteria = buildProgressByCriteria(user);

        badges.forEach(badge -> {
            int currentValue = progressByCriteria.getOrDefault(badge.getCriteriaType(), 0);
            UserBadge awardedBadge = existingBadges.get(badge.getId());
            if (currentValue >= badge.getThreshold() && awardedBadge == null) {
                UserBadge userBadgeToCreate = UserBadge.builder()
                    .user(user)
                    .badge(badge)
                    .awardedAt(LocalDateTime.now())
                    .build();
                userBadgeRepository.save(
                    Objects.requireNonNull(userBadgeToCreate, "user badge must not be null")
                );
            } else if (currentValue < badge.getThreshold() && awardedBadge != null) {
                userBadgeRepository.delete(Objects.requireNonNull(awardedBadge, "awarded badge must not be null"));
            }
        });
    }

    private Map<BadgeCriteriaType, Integer> buildProgressByCriteria(User user) {
        Long userId = requireUserId(user);
        Map<BadgeCriteriaType, Integer> progressByCriteria = new EnumMap<>(BadgeCriteriaType.class);
        progressByCriteria.put(BadgeCriteriaType.TOTAL_LOGS, Math.toIntExact(climbLogRepository.countByUserId(userId)));
        progressByCriteria.put(
            BadgeCriteriaType.COMPLETED_CLIMBS,
            Math.toIntExact(climbLogRepository.countByUserIdAndStatus(userId, ClimbStatus.COMPLETED))
        );
        progressByCriteria.put(
            BadgeCriteriaType.FEEDBACK_RECEIVED,
            Math.toIntExact(feedbackRepository.countByClimberId(userId))
        );
        return progressByCriteria;
    }

    private Long requireUserId(User user) {
        return Objects.requireNonNull(user.getId(), "user id must not be null");
    }
}
