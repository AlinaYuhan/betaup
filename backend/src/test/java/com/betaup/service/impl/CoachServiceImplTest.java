package com.betaup.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.betaup.dto.common.PageQuery;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.UserRepository;
import com.betaup.repository.projection.UserCountProjection;
import com.betaup.security.service.CurrentUserService;
import java.util.List;
import java.util.Objects;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

@ExtendWith(MockitoExtension.class)
class CoachServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private ClimbLogRepository climbLogRepository;

    @Mock
    private FeedbackRepository feedbackRepository;

    @Mock
    private CurrentUserService currentUserService;

    @InjectMocks
    private CoachServiceImpl coachService;

    @Test
    void getClimbersOverviewShouldUseBatchCounts() {
        User coach = User.builder().id(1L).role(UserRole.COACH).build();
        User firstClimber = User.builder().id(10L).name("Ava").email("ava@example.com").role(UserRole.CLIMBER).build();
        User secondClimber = User.builder().id(11L).name("Bo").email("bo@example.com").role(UserRole.CLIMBER).build();

        when(currentUserService.requireRole(UserRole.COACH)).thenReturn(coach);
        List<User> climbers = Objects.requireNonNull(List.of(firstClimber, secondClimber), "climbers must not be null");
        when(userRepository.searchByRole(eq(UserRole.CLIMBER), eq("a"), org.mockito.ArgumentMatchers.any()))
            .thenReturn(new PageImpl<>(climbers, PageRequest.of(0, 8), 2));
        when(climbLogRepository.countByUserIds(List.of(10L, 11L)))
            .thenReturn(List.of(count(10L, 4), count(11L, 1)));
        when(feedbackRepository.countByClimberIds(List.of(10L, 11L)))
            .thenReturn(List.of(count(10L, 2)));

        var response = coachService.getClimbersOverview("a", new PageQuery(0, 8, "createdAt", "desc"));

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getData().items()).hasSize(2);
        assertThat(response.getData().items().getFirst().getClimbCount()).isEqualTo(4);
        assertThat(response.getData().items().getFirst().getFeedbackCount()).isEqualTo(2);
        assertThat(response.getData().items().get(1).getClimbCount()).isEqualTo(1);
        assertThat(response.getData().items().get(1).getFeedbackCount()).isZero();
        verify(climbLogRepository).countByUserIds(List.of(10L, 11L));
        verify(feedbackRepository).countByClimberIds(List.of(10L, 11L));
        verify(climbLogRepository, never()).countByUserId(org.mockito.ArgumentMatchers.anyLong());
        verify(feedbackRepository, never()).countByClimberId(org.mockito.ArgumentMatchers.anyLong());
    }

    private UserCountProjection count(Long userId, long total) {
        return new UserCountProjection() {
            @Override
            public Long getUserId() {
                return userId;
            }

            @Override
            public long getTotal() {
                return total;
            }
        };
    }
}
