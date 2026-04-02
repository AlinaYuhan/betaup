package com.betaup.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.betaup.dto.dashboard.DashboardRange;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.Feedback;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.repository.UserRepository;
import com.betaup.security.service.CurrentUserService;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DashboardServiceImplTest {

    @Mock
    private CurrentUserService currentUserService;

    @Mock
    private ClimbLogRepository climbLogRepository;

    @Mock
    private FeedbackRepository feedbackRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserBadgeRepository userBadgeRepository;

    @InjectMocks
    private DashboardServiceImpl dashboardService;

    @Test
    void getDashboardSummaryShouldPopulateClimberCharts() {
        User climber = User.builder().id(5L).name("Mira").role(UserRole.CLIMBER).build();
        ClimbLog completed = ClimbLog.builder()
            .id(1L)
            .user(climber)
            .routeName("Pebble Push")
            .difficulty("V3")
            .venue("Beta Cave")
            .date(LocalDate.now().minusDays(3))
            .status(ClimbStatus.COMPLETED)
            .createdAt(LocalDateTime.now().minusDays(3))
            .build();
        ClimbLog attempted = ClimbLog.builder()
            .id(2L)
            .user(climber)
            .routeName("Slab Session")
            .difficulty("V4")
            .venue("Beta Cave")
            .date(LocalDate.now().minusMonths(1))
            .status(ClimbStatus.ATTEMPTED)
            .createdAt(LocalDateTime.now().minusMonths(1))
            .build();
        Feedback feedback = Feedback.builder()
            .id(3L)
            .coach(User.builder().id(9L).name("Coach Ren").role(UserRole.COACH).build())
            .climber(climber)
            .climbLog(completed)
            .comment("Better pacing.")
            .rating(4)
            .createdAt(LocalDateTime.now().minusDays(1))
            .build();

        when(currentUserService.getCurrentUser()).thenReturn(climber);
        when(climbLogRepository.findByUserIdOrderByDateDescCreatedAtDesc(5L)).thenReturn(List.of(completed, attempted));
        when(feedbackRepository.findByClimberIdOrderByCreatedAtDesc(5L)).thenReturn(List.of(feedback));
        when(userBadgeRepository.countByUserId(5L)).thenReturn(1L);

        var response = dashboardService.getDashboardSummary(DashboardRange.LAST_180_DAYS);

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getData().getAudience()).isEqualTo("CLIMBER");
        assertThat(response.getData().getRange()).isEqualTo(DashboardRange.LAST_180_DAYS);
        assertThat(response.getData().getCharts()).hasSize(3);
        assertThat(response.getData().getCharts().getFirst().getPoints()).hasSize(6);
        assertThat(response.getData().getBreakdown()).hasSize(4);
        assertThat(response.getData().getMetrics().getFirst().getNumericValue()).isEqualTo(2L);
    }
}
