package com.betaup.service;

import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.entity.User;
import java.util.List;

public interface BadgeAutomationService {

    /** Evaluates badges and returns newly unlocked ones. */
    List<BadgeProgressDto> evaluateUserBadges(User user);

    List<BadgeProgressDto> getProgressForUser(User user);

    void reconcileAllClimberBadges();
}
