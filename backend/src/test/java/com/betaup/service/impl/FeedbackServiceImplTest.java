package com.betaup.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.betaup.dto.common.PageQuery;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.Feedback;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.UserRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.PageRequest;

@ExtendWith(MockitoExtension.class)
class FeedbackServiceImplTest {

    @Mock
    private FeedbackRepository feedbackRepository;

    @Mock
    private ClimbLogRepository climbLogRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CurrentUserService currentUserService;

    @Mock
    private BadgeAutomationService badgeAutomationService;

    @InjectMocks
    private FeedbackServiceImpl feedbackService;

    @Test
    void getMyFeedbackShouldReturnPagedCoachHistory() {
        User coach = User.builder().id(10L).name("Coach Ada").role(UserRole.COACH).build();
        User climber = User.builder().id(20L).name("Lina").role(UserRole.CLIMBER).build();
        ClimbLog climbLog = ClimbLog.builder()
            .id(30L)
            .user(climber)
            .routeName("Skyline Arete")
            .difficulty("V5")
            .venue("North Wall")
            .date(LocalDate.of(2026, 4, 1))
            .status(ClimbStatus.COMPLETED)
            .build();
        Feedback feedback = Feedback.builder()
            .id(40L)
            .coach(coach)
            .climber(climber)
            .climbLog(climbLog)
            .comment("Strong hip drive.")
            .rating(5)
            .createdAt(LocalDateTime.of(2026, 4, 2, 8, 0))
            .build();

        when(currentUserService.getCurrentUser()).thenReturn(coach);
        when(feedbackRepository.findCoachHistory(eq(10L), eq(20L), eq(5), any(Pageable.class)))
            .thenReturn(new PageImpl<>(List.of(feedback), PageRequest.of(1, 6), 9));

        var response = feedbackService.getMyFeedback(20L, 5, new PageQuery(1, 6, "createdAt", "desc"));

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getData().page()).isEqualTo(1);
        assertThat(response.getData().totalElements()).isEqualTo(7);
        assertThat(response.getData().items()).hasSize(1);
        assertThat(response.getData().items().getFirst().getRouteName()).isEqualTo("Skyline Arete");
        assertThat(response.getData().items().getFirst().getDifficulty()).isEqualTo("V5");
        verify(feedbackRepository).findCoachHistory(eq(10L), eq(20L), eq(5), any(Pageable.class));
        verify(feedbackRepository, never()).findClimberHistory(any(), any(), any());
    }
}
