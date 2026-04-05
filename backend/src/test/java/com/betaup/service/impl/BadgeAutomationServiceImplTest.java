package com.betaup.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class BadgeAutomationServiceImplTest {

    @Mock
    private BadgeRepository badgeRepository;

    @Mock
    private UserBadgeRepository userBadgeRepository;

    @Mock
    private ClimbLogRepository climbLogRepository;

    @Mock
    private FeedbackRepository feedbackRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private BadgeAutomationServiceImpl badgeAutomationService;

    @Test
    void getProgressForUserShouldReuseCriteriaCounts() {
        User climber = User.builder().id(7L).build();
        Badge totalLogsFive = badge(1L, BadgeCriteriaType.TOTAL_LOGS, 5, "TOTAL_5");
        Badge totalLogsTen = badge(2L, BadgeCriteriaType.TOTAL_LOGS, 10, "TOTAL_10");
        Badge feedbackOne = badge(3L, BadgeCriteriaType.FEEDBACK_RECEIVED, 1, "FDBK_1");
        UserBadge earnedBadge = UserBadge.builder()
            .id(99L)
            .user(climber)
            .badge(totalLogsFive)
            .awardedAt(LocalDateTime.now())
            .build();

        when(userBadgeRepository.findByUserIdOrderByAwardedAtDesc(7L)).thenReturn(List.of(earnedBadge));
        when(badgeRepository.findAllByOrderByThresholdAsc()).thenReturn(List.of(totalLogsFive, totalLogsTen, feedbackOne));
        when(climbLogRepository.countByUserId(7L)).thenReturn(8L);
        when(climbLogRepository.countByUserIdAndStatus(7L, ClimbStatus.COMPLETED)).thenReturn(3L);
        when(feedbackRepository.countByClimberId(7L)).thenReturn(1L);

        List<BadgeProgressDto> progress = badgeAutomationService.getProgressForUser(climber);

        assertThat(progress).hasSize(3);
        assertThat(progress).extracting(BadgeProgressDto::getCurrentValue).containsExactly(8, 8, 1);
        verify(climbLogRepository, times(1)).countByUserId(7L);
        verify(climbLogRepository, times(1)).countByUserIdAndStatus(7L, ClimbStatus.COMPLETED);
        verify(feedbackRepository, times(1)).countByClimberId(7L);
    }

    @Test
    @SuppressWarnings("null")
    void evaluateUserBadgesShouldComputeCriteriaOncePerUser() {
        User climber = User.builder().id(7L).build();
        Badge totalLogsFive = badge(1L, BadgeCriteriaType.TOTAL_LOGS, 5, "TOTAL_5");
        Badge totalLogsTen = badge(2L, BadgeCriteriaType.TOTAL_LOGS, 10, "TOTAL_10");
        Badge feedbackOne = badge(3L, BadgeCriteriaType.FEEDBACK_RECEIVED, 1, "FDBK_1");

        when(badgeRepository.findAllByOrderByThresholdAsc()).thenReturn(List.of(totalLogsFive, totalLogsTen, feedbackOne));
        when(userBadgeRepository.findByUserId(7L)).thenReturn(List.of());
        when(climbLogRepository.countByUserId(7L)).thenReturn(8L);
        when(climbLogRepository.countByUserIdAndStatus(7L, ClimbStatus.COMPLETED)).thenReturn(3L);
        when(feedbackRepository.countByClimberId(7L)).thenReturn(1L);

        badgeAutomationService.evaluateUserBadges(climber);

        verify(climbLogRepository, times(1)).countByUserId(7L);
        verify(climbLogRepository, times(1)).countByUserIdAndStatus(7L, ClimbStatus.COMPLETED);
        verify(feedbackRepository, times(1)).countByClimberId(7L);
        verify(userBadgeRepository, times(2)).save(any(UserBadge.class));
    }

    private Badge badge(Long id, BadgeCriteriaType criteriaType, int threshold, String badgeKey) {
        return Badge.builder()
            .id(id)
            .badgeKey(badgeKey)
            .name(badgeKey)
            .description(badgeKey)
            .criteriaType(criteriaType)
            .threshold(threshold)
            .build();
    }
}
