package com.betaup.service.impl;

import com.betaup.dto.climb.ClimbLogRequest;
import com.betaup.dto.climb.ClimbLogResponse;
import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.exception.ResourceNotFoundException;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import com.betaup.service.ClimbService;
import com.betaup.util.PageableFactory;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ClimbServiceImpl implements ClimbService {

    private final ClimbLogRepository climbLogRepository;
    private final FeedbackRepository feedbackRepository;
    private final CurrentUserService currentUserService;
    private final BadgeAutomationService badgeAutomationService;

    @Override
    public ApiResponse<String> getStatus() {
        return ApiResponse.success("Climb logging module is live.", "CLIMB_READY");
    }

    @Override
    public ApiResponse<PageResponse<ClimbLogResponse>> getClimbLogs(PageQuery pageQuery) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        Pageable pageable = PageableFactory.create(
            pageQuery,
            6,
            "date",
            Sort.Direction.DESC,
            Map.of(
                "date", "date",
                "createdAt", "createdAt",
                "routeName", "routeName",
                "difficulty", "difficulty",
                "venue", "venue"
            )
        );
        Page<ClimbLogResponse> data = climbLogRepository.findByUserId(user.getId(), pageable).map(this::toResponse);

        return ApiResponse.success("Climb logs loaded.", PageResponse.from(data));
    }

    @Override
    public ApiResponse<ClimbLogResponse> getClimbLog(Long climbLogId) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        return ApiResponse.success("Climb log loaded.", toResponse(findOwnedClimbLog(user, climbLogId)));
    }

    @Override
    @Transactional
    public ApiResponse<ClimbLogResponse> createClimbLog(ClimbLogRequest request) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        ClimbLog climbLog = climbLogRepository.save(
            ClimbLog.builder()
                .user(user)
                .routeName(request.getRouteName().trim())
                .difficulty(request.getDifficulty().trim())
                .date(request.getDate())
                .venue(request.getVenue().trim())
                .status(request.getStatus())
                .notes(request.getNotes() == null ? null : request.getNotes().trim())
                .build()
        );
        badgeAutomationService.evaluateUserBadges(user);

        return ApiResponse.success("Climb log created.", toResponse(climbLog));
    }

    @Override
    @Transactional
    public ApiResponse<ClimbLogResponse> updateClimbLog(Long climbLogId, ClimbLogRequest request) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        ClimbLog climbLog = findOwnedClimbLog(user, climbLogId);
        climbLog.setRouteName(request.getRouteName().trim());
        climbLog.setDifficulty(request.getDifficulty().trim());
        climbLog.setDate(request.getDate());
        climbLog.setVenue(request.getVenue().trim());
        climbLog.setStatus(request.getStatus());
        climbLog.setNotes(request.getNotes() == null ? null : request.getNotes().trim());

        badgeAutomationService.evaluateUserBadges(user);
        return ApiResponse.success("Climb log updated.", toResponse(climbLog));
    }

    @Override
    @Transactional
    public ApiResponse<Void> deleteClimbLog(Long climbLogId) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        ClimbLog climbLog = findOwnedClimbLog(user, climbLogId);
        if (feedbackRepository.countByClimbLogId(climbLogId) > 0) {
            throw new IllegalArgumentException("Cannot delete a climb log that already has coach feedback.");
        }

        climbLogRepository.delete(climbLog);
        return ApiResponse.success("Climb log deleted.", null);
    }

    private ClimbLog findOwnedClimbLog(User user, Long climbLogId) {
        ClimbLog climbLog = climbLogRepository.findById(climbLogId)
            .orElseThrow(() -> new ResourceNotFoundException("Climb log not found."));
        if (!climbLog.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("You do not have access to this climb log.");
        }
        return climbLog;
    }

    private ClimbLogResponse toResponse(ClimbLog climbLog) {
        return ClimbLogResponse.builder()
            .id(climbLog.getId())
            .userId(climbLog.getUser().getId())
            .routeName(climbLog.getRouteName())
            .difficulty(climbLog.getDifficulty())
            .date(climbLog.getDate())
            .venue(climbLog.getVenue())
            .status(climbLog.getStatus())
            .notes(climbLog.getNotes())
            .createdAt(climbLog.getCreatedAt())
            .build();
    }
}
