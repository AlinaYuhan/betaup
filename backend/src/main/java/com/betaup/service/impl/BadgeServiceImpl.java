package com.betaup.service.impl;

import com.betaup.dto.badge.BadgeDto;
import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.dto.badge.CreateBadgeRuleRequest;
import com.betaup.dto.badge.UpdateBadgeRuleRequest;
import com.betaup.dto.badge.UserBadgeDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.entity.Badge;
import com.betaup.entity.UserRole;
import com.betaup.entity.UserBadge;
import com.betaup.exception.ConflictException;
import com.betaup.exception.ResourceNotFoundException;
import com.betaup.repository.BadgeRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import com.betaup.service.BadgeService;
import java.util.List;
import java.util.Objects;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BadgeServiceImpl implements BadgeService {

    private final BadgeRepository badgeRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final CurrentUserService currentUserService;
    private final BadgeAutomationService badgeAutomationService;

    @Override
    public ApiResponse<String> getStatus() {
        return ApiResponse.success("Badge catalog endpoints are live.", "BADGE_READY");
    }

    @Override
    public ApiResponse<List<BadgeDto>> getBadges() {
        List<BadgeDto> data = badgeRepository.findAllByOrderByThresholdAsc()
            .stream()
            .map(this::toBadgeDto)
            .toList();

        return ApiResponse.success("Badge catalog loaded.", data);
    }

    @Override
    public ApiResponse<List<BadgeDto>> getBadgeRules() {
        currentUserService.requireRole(UserRole.COACH);
        List<BadgeDto> data = badgeRepository.findAllByOrderByThresholdAsc()
            .stream()
            .map(this::toBadgeDto)
            .toList();

        return ApiResponse.success("Badge rules loaded.", data);
    }

    @Override
    public ApiResponse<List<UserBadgeDto>> getMyBadges() {
        Long userId = Objects.requireNonNull(currentUserService.getCurrentUser().getId(), "user id must not be null");
        List<UserBadgeDto> data = userBadgeRepository.findByUserIdOrderByAwardedAtDesc(userId)
            .stream()
            .map(this::toUserBadgeDto)
            .toList();

        return ApiResponse.success("User badges loaded.", data);
    }

    @Override
    public ApiResponse<List<BadgeProgressDto>> getMyBadgeProgress() {
        return ApiResponse.success(
            "Badge progress loaded.",
            badgeAutomationService.getProgressForUser(currentUserService.getCurrentUser())
        );
    }

    @Override
    @Transactional
    public ApiResponse<BadgeDto> createBadgeRule(CreateBadgeRuleRequest request) {
        currentUserService.requireRole(UserRole.COACH);
        String badgeKey = normalizeBadgeKey(request.getBadgeKey());
        if (badgeRepository.existsByBadgeKeyIgnoreCase(badgeKey)) {
            throw new ConflictException("Badge key already exists.");
        }

        Badge badgeToCreate = Badge.builder()
            .badgeKey(badgeKey)
            .name(request.getName().trim())
            .description(request.getDescription().trim())
            .threshold(request.getThreshold())
            .criteriaType(request.getCriteriaType())
            .build();
        Badge badge = badgeRepository.save(
            Objects.requireNonNull(badgeToCreate, "badge must not be null")
        );
        badgeAutomationService.reconcileAllClimberBadges();
        return ApiResponse.success("Badge rule created.", toBadgeDto(badge));
    }

    @Override
    @Transactional
    public ApiResponse<BadgeDto> updateBadgeRule(Long badgeId, UpdateBadgeRuleRequest request) {
        currentUserService.requireRole(UserRole.COACH);
        Long requiredBadgeId = Objects.requireNonNull(badgeId, "badgeId must not be null");
        Badge badge = badgeRepository.findById(requiredBadgeId)
            .orElseThrow(() -> new ResourceNotFoundException("Badge rule not found."));

        badge.setName(request.getName().trim());
        badge.setDescription(request.getDescription().trim());
        badge.setThreshold(request.getThreshold());
        badge.setCriteriaType(request.getCriteriaType());

        badgeAutomationService.reconcileAllClimberBadges();
        return ApiResponse.success("Badge rule updated.", toBadgeDto(badge));
    }

    @Override
    @Transactional
    public ApiResponse<Void> deleteBadgeRule(Long badgeId) {
        currentUserService.requireRole(UserRole.COACH);
        Long requiredBadgeId = Objects.requireNonNull(badgeId, "badgeId must not be null");
        Badge badge = badgeRepository.findById(requiredBadgeId)
            .orElseThrow(() -> new ResourceNotFoundException("Badge rule not found."));

        userBadgeRepository.deleteByBadgeId(requiredBadgeId);
        badgeRepository.delete(Objects.requireNonNull(badge, "badge must not be null"));
        badgeAutomationService.reconcileAllClimberBadges();
        return ApiResponse.success("Badge rule deleted.", null);
    }

    private BadgeDto toBadgeDto(Badge badge) {
        return BadgeDto.builder()
            .id(badge.getId())
            .badgeKey(badge.getBadgeKey())
            .name(badge.getName())
            .description(badge.getDescription())
            .threshold(badge.getThreshold())
            .criteriaType(badge.getCriteriaType())
            .createdAt(badge.getCreatedAt())
            .build();
    }

    private UserBadgeDto toUserBadgeDto(UserBadge userBadge) {
        return UserBadgeDto.builder()
            .id(userBadge.getId())
            .badgeId(userBadge.getBadge().getId())
            .badgeKey(userBadge.getBadge().getBadgeKey())
            .name(userBadge.getBadge().getName())
            .description(userBadge.getBadge().getDescription())
            .threshold(userBadge.getBadge().getThreshold())
            .criteriaType(userBadge.getBadge().getCriteriaType())
            .awardedAt(userBadge.getAwardedAt())
            .build();
    }

    private String normalizeBadgeKey(String rawBadgeKey) {
        return rawBadgeKey.trim().toUpperCase().replace(' ', '_');
    }
}
