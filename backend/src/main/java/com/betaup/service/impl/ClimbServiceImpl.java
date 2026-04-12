package com.betaup.service.impl;

import com.betaup.dto.climb.ClimbLogRequest;
import com.betaup.dto.climb.ClimbLogResponse;
import com.betaup.dto.climb.GradeStatDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbResult;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.exception.ResourceNotFoundException;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import com.betaup.service.ClimbService;
import com.betaup.util.PageableFactory;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
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
        Long requiredClimbLogId = Objects.requireNonNull(climbLogId, "climbLogId must not be null");
        return ApiResponse.success("Climb log loaded.", toResponse(findOwnedClimbLog(user, requiredClimbLogId)));
    }

    @Override
    @Transactional
    public ApiResponse<ClimbLogResponse> createClimbLog(ClimbLogRequest request) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        ClimbResult result = request.getResult() != null ? request.getResult() : ClimbResult.SEND;
        ClimbLog climbLogToCreate = ClimbLog.builder()
            .user(user)
            .routeName(request.getRouteName() != null ? request.getRouteName().trim() : "")
            .difficulty(request.getDifficulty() != null ? request.getDifficulty().trim() : "")
            .date(request.getDate())
            .venue(request.getVenue() != null ? request.getVenue().trim() : "")
            .result(result)
            .status(deriveStatus(result))
            .attempts(request.getAttempts() != null ? request.getAttempts() : 1)
            .sessionId(request.getSessionId())
            .notes(request.getNotes() == null ? null : request.getNotes().trim())
            .build();
        ClimbLog climbLog = climbLogRepository.save(
            Objects.requireNonNull(climbLogToCreate, "climb log must not be null")
        );
        var newBadges = badgeAutomationService.evaluateUserBadges(user);
        ClimbLogResponse response = toResponse(climbLog);
        response.setNewlyUnlockedBadges(newBadges.isEmpty() ? null : newBadges);
        return ApiResponse.success("Climb log created.", response);
    }

    @Override
    @Transactional
    public ApiResponse<ClimbLogResponse> updateClimbLog(Long climbLogId, ClimbLogRequest request) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        Long requiredClimbLogId = Objects.requireNonNull(climbLogId, "climbLogId must not be null");
        ClimbLog climbLog = findOwnedClimbLog(user, requiredClimbLogId);
        ClimbResult result = request.getResult() != null ? request.getResult() : ClimbResult.SEND;
        climbLog.setRouteName(request.getRouteName() != null ? request.getRouteName().trim() : "");
        climbLog.setDifficulty(request.getDifficulty() != null ? request.getDifficulty().trim() : "");
        climbLog.setDate(request.getDate());
        climbLog.setVenue(request.getVenue() != null ? request.getVenue().trim() : "");
        climbLog.setResult(result);
        climbLog.setStatus(deriveStatus(result));
        climbLog.setSessionId(request.getSessionId());
        climbLog.setAttempts(request.getAttempts() != null ? request.getAttempts() : 1);
        climbLog.setNotes(request.getNotes() == null ? null : request.getNotes().trim());

        badgeAutomationService.evaluateUserBadges(user);
        return ApiResponse.success("Climb log updated.", toResponse(climbLog));
    }

    @Override
    @Transactional
    public ApiResponse<Void> deleteClimbLog(Long climbLogId) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        Long requiredClimbLogId = Objects.requireNonNull(climbLogId, "climbLogId must not be null");
        ClimbLog climbLog = findOwnedClimbLog(user, requiredClimbLogId);
        if (feedbackRepository.countByClimbLogId(requiredClimbLogId) > 0) {
            throw new IllegalArgumentException("Cannot delete a climb log that already has coach feedback.");
        }

        climbLogRepository.delete(Objects.requireNonNull(climbLog, "climb log must not be null"));
        return ApiResponse.success("Climb log deleted.", null);
    }

    @Override
    public ApiResponse<List<GradeStatDto>> getGradeStats() {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        List<ClimbLog> logs = climbLogRepository.findByUserIdOrderByDateDescCreatedAtDesc(user.getId());

        Map<String, List<ClimbLog>> byGrade = logs.stream()
            .filter(l -> l.getDifficulty() != null && !l.getDifficulty().isBlank())
            .collect(Collectors.groupingBy(ClimbLog::getDifficulty));

        List<GradeStatDto> stats = byGrade.entrySet().stream()
            .map(entry -> {
                List<ClimbLog> gradeLogs = entry.getValue();
                long total = gradeLogs.size();
                long flashes = gradeLogs.stream()
                    .filter(l -> l.getResult() == ClimbResult.FLASH)
                    .count();
                long sends = gradeLogs.stream()
                    .filter(l -> l.getResult() == ClimbResult.FLASH || l.getResult() == ClimbResult.SEND
                        || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED))
                    .count();
                return GradeStatDto.builder()
                    .difficulty(entry.getKey())
                    .total(total)
                    .sends(sends)
                    .flashes(flashes)
                    .build();
            })
            .sorted((a, b) -> compareGrades(a.getDifficulty(), b.getDifficulty()))
            .toList();

        return ApiResponse.success("Grade stats loaded.", stats);
    }

    // ── helpers ──────────────────────────────────────────────────────────────

    private static ClimbStatus deriveStatus(ClimbResult result) {
        return result == ClimbResult.ATTEMPT ? ClimbStatus.ATTEMPTED : ClimbStatus.COMPLETED;
    }

    /** Sort VB < V0 < V1 ... < V12; unknowns go last alphabetically. */
    private static int compareGrades(String a, String b) {
        return Integer.compare(gradeOrder(a), gradeOrder(b));
    }

    private static int gradeOrder(String grade) {
        if (grade == null) return 999;
        String up = grade.trim().toUpperCase();
        if (up.equals("VB")) return -1;
        if (up.startsWith("V")) {
            try { return Integer.parseInt(up.substring(1)); } catch (NumberFormatException ignored) {}
        }
        return 100 + up.charAt(0);
    }

    private ClimbLog findOwnedClimbLog(User user, Long climbLogId) {
        ClimbLog climbLog = climbLogRepository.findDetailedById(climbLogId)
            .orElseThrow(() -> new ResourceNotFoundException("Climb log not found."));
        if (!climbLog.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("You do not have access to this climb log.");
        }
        return climbLog;
    }

    private ClimbLogResponse toResponse(ClimbLog climbLog) {
        ClimbResult result = climbLog.getResult() != null
            ? climbLog.getResult()
            : (climbLog.getStatus() == ClimbStatus.COMPLETED ? ClimbResult.SEND : ClimbResult.ATTEMPT);
        return ClimbLogResponse.builder()
            .id(climbLog.getId())
            .userId(climbLog.getUser().getId())
            .sessionId(climbLog.getSessionId())
            .routeName(climbLog.getRouteName())
            .difficulty(climbLog.getDifficulty())
            .date(climbLog.getDate())
            .venue(climbLog.getVenue())
            .status(climbLog.getStatus())
            .result(result)
            .attempts(climbLog.getAttempts())
            .notes(climbLog.getNotes())
            .createdAt(climbLog.getCreatedAt())
            .build();
    }
}
