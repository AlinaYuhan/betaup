package com.betaup.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.betaup.dto.badge.CreateBadgeRuleRequest;
import com.betaup.dto.badge.UpdateBadgeRuleRequest;
import com.betaup.entity.Badge;
import com.betaup.entity.BadgeCriteriaType;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.repository.BadgeRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class BadgeServiceImplTest {

    @Mock
    private BadgeRepository badgeRepository;

    @Mock
    private UserBadgeRepository userBadgeRepository;

    @Mock
    private CurrentUserService currentUserService;

    @Mock
    private BadgeAutomationService badgeAutomationService;

    @InjectMocks
    private BadgeServiceImpl badgeService;

    @Test
    void createBadgeRuleShouldNormalizeKeyAndTriggerResync() {
        User coach = User.builder().id(1L).role(UserRole.COACH).build();
        CreateBadgeRuleRequest request = CreateBadgeRuleRequest.builder()
            .badgeKey("send 25")
            .name("Send 25")
            .description("Complete twenty five climbs.")
            .threshold(25)
            .criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
            .build();

        when(currentUserService.requireRole(UserRole.COACH)).thenReturn(coach);
        when(badgeRepository.existsByBadgeKeyIgnoreCase("SEND_25")).thenReturn(false);
        when(badgeRepository.save(any(Badge.class))).thenAnswer(invocation -> {
            Badge badge = invocation.getArgument(0);
            badge.setId(42L);
            return badge;
        });

        var response = badgeService.createBadgeRule(request);

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getData().getBadgeKey()).isEqualTo("SEND_25");
        assertThat(response.getData().getThreshold()).isEqualTo(25);
        verify(badgeAutomationService).reconcileAllClimberBadges();
    }

    @Test
    void updateBadgeRuleShouldPersistMutations() {
        User coach = User.builder().id(1L).role(UserRole.COACH).build();
        Badge existingBadge = Badge.builder()
            .id(8L)
            .badgeKey("FIRST_SEND")
            .name("First Send")
            .description("Old description")
            .threshold(1)
            .criteriaType(BadgeCriteriaType.COMPLETED_CLIMBS)
            .build();
        UpdateBadgeRuleRequest request = UpdateBadgeRuleRequest.builder()
            .name("Send Starter")
            .description("Updated description")
            .threshold(2)
            .criteriaType(BadgeCriteriaType.TOTAL_LOGS)
            .build();

        when(currentUserService.requireRole(UserRole.COACH)).thenReturn(coach);
        when(badgeRepository.findById(8L)).thenReturn(java.util.Optional.of(existingBadge));

        var response = badgeService.updateBadgeRule(8L, request);

        assertThat(response.isSuccess()).isTrue();
        assertThat(existingBadge.getName()).isEqualTo("Send Starter");
        assertThat(existingBadge.getDescription()).isEqualTo("Updated description");
        assertThat(existingBadge.getThreshold()).isEqualTo(2);
        assertThat(existingBadge.getCriteriaType()).isEqualTo(BadgeCriteriaType.TOTAL_LOGS);
        verify(badgeAutomationService).reconcileAllClimberBadges();
    }
}
