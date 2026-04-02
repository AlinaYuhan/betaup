package com.betaup.service;

import com.betaup.dto.badge.BadgeDto;
import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.dto.badge.CreateBadgeRuleRequest;
import com.betaup.dto.badge.UpdateBadgeRuleRequest;
import com.betaup.dto.badge.UserBadgeDto;
import com.betaup.dto.common.ApiResponse;
import java.util.List;

public interface BadgeService {

    ApiResponse<String> getStatus();

    ApiResponse<List<BadgeDto>> getBadges();

    ApiResponse<List<BadgeDto>> getBadgeRules();

    ApiResponse<List<UserBadgeDto>> getMyBadges();

    ApiResponse<List<BadgeProgressDto>> getMyBadgeProgress();

    ApiResponse<BadgeDto> createBadgeRule(CreateBadgeRuleRequest request);

    ApiResponse<BadgeDto> updateBadgeRule(Long badgeId, UpdateBadgeRuleRequest request);

    ApiResponse<Void> deleteBadgeRule(Long badgeId);
}
