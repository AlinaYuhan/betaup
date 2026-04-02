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
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
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
        List<UserBadge> earnedBadges = userBadgeRepository.findByUserIdOrderByAwardedAtDesc(user.getId());
        List<Badge> allBadges = badgeRepository.findAllByOrderByThresholdAsc();

        return allBadges.stream().map(badge -> {
            UserBadge earnedBadge = earnedBadges.stream()
                .filter(userBadge -> userBadge.getBadge().getId().equals(badge.getId()))
                .findFirst()
                .orElse(null);

            return BadgeProgressDto.builder()
                .badgeId(badge.getId())
                .badgeKey(badge.getBadgeKey())
                .name(badge.getName())
                .description(badge.getDescription())
                .criteriaType(badge.getCriteriaType())
                .threshold(badge.getThreshold())
                .currentValue(currentValueFor(user, badge.getCriteriaType()))
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
        Map<Long, UserBadge> existingBadges = userBadgeRepository.findByUserId(user.getId())
            .stream()
            .collect(Collectors.toMap(userBadge -> userBadge.getBadge().getId(), Function.identity()));

        badges.forEach(badge -> {
            int currentValue = currentValueFor(user, badge.getCriteriaType());
            UserBadge awardedBadge = existingBadges.get(badge.getId());
            if (currentValue >= badge.getThreshold() && awardedBadge == null) {
                userBadgeRepository.save(
                    UserBadge.builder()
                        .user(user)
                        .badge(badge)
                        .awardedAt(LocalDateTime.now())
                        .build()
                );
            } else if (currentValue < badge.getThreshold() && awardedBadge != null) {
                userBadgeRepository.delete(awardedBadge);
            }
        });
    }

    private int currentValueFor(User user, BadgeCriteriaType criteriaType) {
        return switch (criteriaType) {
            case TOTAL_LOGS -> Math.toIntExact(climbLogRepository.countByUserId(user.getId()));
            case COMPLETED_CLIMBS -> Math.toIntExact(
                climbLogRepository.countByUserIdAndStatus(user.getId(), ClimbStatus.COMPLETED)
            );
            case FEEDBACK_RECEIVED -> Math.toIntExact(feedbackRepository.countByClimberId(user.getId()));
        };
    }
}
