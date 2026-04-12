package com.betaup.service.impl;

import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.dto.climb.GradeStatDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageResponse;
import com.betaup.dto.session.SessionDto;
import com.betaup.dto.session.SessionStartRequest;
import com.betaup.dto.session.SessionSummaryDto;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbResult;
import com.betaup.entity.ClimbSession;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.exception.ResourceNotFoundException;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.ClimbSessionRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import com.betaup.service.SessionService;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SessionServiceImpl implements SessionService {

    private final ClimbSessionRepository sessionRepository;
    private final ClimbLogRepository climbLogRepository;
    private final CurrentUserService currentUserService;
    private final BadgeAutomationService badgeAutomationService;

    @Override
    @Transactional
    public ApiResponse<SessionDto> startSession(SessionStartRequest request) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);

        // End any lingering active session first
        sessionRepository.findByUserIdAndEndTimeIsNull(user.getId())
            .ifPresent(s -> { s.setEndTime(LocalDateTime.now()); sessionRepository.save(s); });

        ClimbSession session = ClimbSession.builder()
            .user(user)
            .venue(request.getVenue() != null ? request.getVenue().trim() : "")
            .startTime(LocalDateTime.now())
            .build();
        session = sessionRepository.save(session);
        return ApiResponse.success("Session started.", toDto(session));
    }

    @Override
    public ApiResponse<SessionDto> getActiveSession() {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        return sessionRepository.findByUserIdAndEndTimeIsNull(user.getId())
            .map(s -> ApiResponse.success("Active session found.", toDto(s)))
            .orElse(ApiResponse.success("No active session.", null));
    }

    @Override
    @Transactional
    public ApiResponse<SessionSummaryDto> endSession(Long sessionId) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        ClimbSession session = sessionRepository.findByIdAndUserId(sessionId, user.getId())
            .orElseThrow(() -> new ResourceNotFoundException("Session not found."));

        session.setEndTime(LocalDateTime.now());
        sessionRepository.save(session);

        List<BadgeProgressDto> newBadges = badgeAutomationService.evaluateUserBadges(user);
        SessionSummaryDto summary = buildSummary(session, user.getId());
        summary.setNewlyUnlockedBadges(newBadges.isEmpty() ? null : newBadges);
        return ApiResponse.success("Session ended.", summary);
    }

    @Override
    public ApiResponse<PageResponse<SessionSummaryDto>> getUserSessions(int page, int size) {
        User user = currentUserService.requireRole(UserRole.CLIMBER);
        var pageable = PageRequest.of(page, size);
        var sessionPage = sessionRepository
            .findByUserIdAndEndTimeIsNotNullOrderByStartTimeDesc(user.getId(), pageable);

        // Batch load logs for all sessions in one query
        List<Long> sessionIds = sessionPage.getContent().stream()
            .map(ClimbSession::getId).toList();
        Map<Long, List<ClimbLog>> logsBySession = sessionIds.isEmpty()
            ? Map.of()
            : climbLogRepository.findBySessionIdIn(sessionIds).stream()
                .collect(Collectors.groupingBy(ClimbLog::getSessionId));

        var summaries = sessionPage.getContent().stream()
            .map(s -> buildLightSummary(s, logsBySession.getOrDefault(s.getId(), List.of())))
            .toList();

        var mapped = new org.springframework.data.domain.PageImpl<>(
            summaries, pageable, sessionPage.getTotalElements());
        return ApiResponse.success("Sessions loaded.", PageResponse.from(mapped));
    }

    // ── helpers ────────────────────────────────────────────────────────────

    private SessionSummaryDto buildLightSummary(ClimbSession session, List<ClimbLog> logs) {
        int flashes = (int) logs.stream().filter(l -> l.getResult() == ClimbResult.FLASH).count();
        int sends = (int) logs.stream()
            .filter(l -> l.getResult() == ClimbResult.SEND
                || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED))
            .count();
        int attempts = (int) logs.stream()
            .filter(l -> l.getResult() == ClimbResult.ATTEMPT
                || (l.getResult() == null && l.getStatus() == ClimbStatus.ATTEMPTED))
            .count();
        String hardestSend = logs.stream()
            .filter(l -> l.getResult() == ClimbResult.FLASH || l.getResult() == ClimbResult.SEND
                || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED))
            .map(ClimbLog::getDifficulty)
            .filter(d -> d != null && !d.isBlank())
            .max((a, b) -> Integer.compare(gradeOrder(a), gradeOrder(b)))
            .orElse(null);
        LocalDateTime end = session.getEndTime() != null ? session.getEndTime() : LocalDateTime.now();
        int durationMinutes = (int) Duration.between(session.getStartTime(), end).toMinutes();
        return SessionSummaryDto.builder()
            .sessionId(session.getId())
            .venue(session.getVenue())
            .startTime(session.getStartTime())
            .endTime(session.getEndTime())
            .durationMinutes(durationMinutes)
            .totalLogs(logs.size())
            .flashes(flashes)
            .sends(sends)
            .attempts(attempts)
            .hardestSend(hardestSend)
            .gradeSummary(List.of())
            .build();
    }

    private SessionSummaryDto buildSummary(ClimbSession session, Long userId) {
        List<ClimbLog> logs = climbLogRepository.findByUserIdOrderByDateDescCreatedAtDesc(userId)
            .stream()
            .filter(l -> session.getId().equals(l.getSessionId()))
            .toList();

        int flashes = (int) logs.stream().filter(l -> l.getResult() == ClimbResult.FLASH).count();
        int sends = (int) logs.stream()
            .filter(l -> l.getResult() == ClimbResult.SEND
                || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED))
            .count();
        int attempts = (int) logs.stream()
            .filter(l -> l.getResult() == ClimbResult.ATTEMPT
                || (l.getResult() == null && l.getStatus() == ClimbStatus.ATTEMPTED))
            .count();

        String hardestSend = logs.stream()
            .filter(l -> l.getResult() == ClimbResult.FLASH || l.getResult() == ClimbResult.SEND
                || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED))
            .map(ClimbLog::getDifficulty)
            .filter(d -> d != null && !d.isBlank())
            .max((a, b) -> Integer.compare(gradeOrder(a), gradeOrder(b)))
            .orElse(null);

        Map<String, List<ClimbLog>> byGrade = logs.stream()
            .filter(l -> l.getDifficulty() != null && !l.getDifficulty().isBlank())
            .collect(Collectors.groupingBy(ClimbLog::getDifficulty));

        List<GradeStatDto> gradeSummary = byGrade.entrySet().stream()
            .map(e -> {
                long total = e.getValue().size();
                long gFlashes = e.getValue().stream().filter(l -> l.getResult() == ClimbResult.FLASH).count();
                long gSends = e.getValue().stream()
                    .filter(l -> l.getResult() == ClimbResult.FLASH || l.getResult() == ClimbResult.SEND
                        || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED))
                    .count();
                return GradeStatDto.builder()
                    .difficulty(e.getKey()).total(total).sends(gSends).flashes(gFlashes).build();
            })
            .sorted((a, b) -> Integer.compare(gradeOrder(a.getDifficulty()), gradeOrder(b.getDifficulty())))
            .toList();

        LocalDateTime end = session.getEndTime() != null ? session.getEndTime() : LocalDateTime.now();
        int durationMinutes = (int) Duration.between(session.getStartTime(), end).toMinutes();

        return SessionSummaryDto.builder()
            .sessionId(session.getId())
            .venue(session.getVenue())
            .startTime(session.getStartTime())
            .endTime(session.getEndTime())
            .durationMinutes(durationMinutes)
            .totalLogs(logs.size())
            .flashes(flashes)
            .sends(sends)
            .attempts(attempts)
            .hardestSend(hardestSend)
            .gradeSummary(gradeSummary)
            .build();
    }

    private static SessionDto toDto(ClimbSession s) {
        return SessionDto.builder()
            .id(s.getId())
            .userId(s.getUser().getId())
            .venue(s.getVenue())
            .startTime(s.getStartTime())
            .endTime(s.getEndTime())
            .active(s.getEndTime() == null)
            .build();
    }

    private static int gradeOrder(String grade) {
        if (grade == null) return 999;
        String up = grade.trim().toUpperCase();
        if (up.equals("VB")) return -1;
        if (up.startsWith("V")) {
            try { return Integer.parseInt(up.substring(1)); } catch (NumberFormatException ignored) {}
        }
        return 100;
    }
}
