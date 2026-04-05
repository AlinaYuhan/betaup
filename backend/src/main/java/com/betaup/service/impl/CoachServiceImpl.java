package com.betaup.service.impl;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.ClimberDetailDto;
import com.betaup.dto.common.ClimberOverviewDto;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import com.betaup.dto.climb.ClimbLogResponse;
import com.betaup.dto.feedback.FeedbackDto;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.exception.ResourceNotFoundException;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.UserRepository;
import com.betaup.repository.projection.UserCountProjection;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.CoachService;
import com.betaup.util.PageableFactory;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CoachServiceImpl implements CoachService {

    private final UserRepository userRepository;
    private final ClimbLogRepository climbLogRepository;
    private final FeedbackRepository feedbackRepository;
    private final CurrentUserService currentUserService;

    @Override
    public ApiResponse<String> getStatus() {
        return ApiResponse.success("Coach module is live.", "COACH_READY");
    }

    @Override
    public ApiResponse<PageResponse<ClimberOverviewDto>> getClimbersOverview(String query, PageQuery pageQuery) {
        currentUserService.requireRole(UserRole.COACH);
        Pageable pageable = PageableFactory.create(
            pageQuery,
            8,
            "createdAt",
            Sort.Direction.DESC,
            Map.of(
                "createdAt", "createdAt",
                "name", "name",
                "email", "email"
            )
        );
        String normalizedQuery = query == null || query.isBlank() ? null : query.trim();
        Page<User> climberPage = userRepository.searchByRole(UserRole.CLIMBER, normalizedQuery, pageable);
        Map<Long, Long> climbCounts = loadClimbCounts(climberPage.getContent());
        Map<Long, Long> feedbackCounts = loadFeedbackCounts(climberPage.getContent());
        Page<ClimberOverviewDto> data = climberPage.map(user -> toClimberOverview(user, climbCounts, feedbackCounts));

        return ApiResponse.success("Climber roster loaded.", PageResponse.from(data));
    }

    @Override
    public ApiResponse<List<ClimberOverviewDto>> getClimberOptions() {
        currentUserService.requireRole(UserRole.COACH);
        List<User> climbers = userRepository.findByRoleOrderByNameAsc(UserRole.CLIMBER);
        Map<Long, Long> climbCounts = loadClimbCounts(climbers);
        Map<Long, Long> feedbackCounts = loadFeedbackCounts(climbers);
        List<ClimberOverviewDto> data = climbers.stream()
            .map(user -> toClimberOverview(user, climbCounts, feedbackCounts))
            .toList();

        return ApiResponse.success("Climber options loaded.", data);
    }

    @Override
    public ApiResponse<ClimberDetailDto> getClimberDetail(Long climberId) {
        currentUserService.requireRole(UserRole.COACH);
        Long requiredClimberId = Objects.requireNonNull(climberId, "climberId must not be null");
        User climber = userRepository.findById(requiredClimberId)
            .orElseThrow(() -> new ResourceNotFoundException("Climber not found."));
        if (climber.getRole() != UserRole.CLIMBER) {
            throw new IllegalArgumentException("Selected user is not a climber.");
        }

        List<ClimbLogResponse> recentClimbs = climbLogRepository.findTop5ByUserIdOrderByDateDescCreatedAtDesc(requiredClimberId)
            .stream()
            .map(this::toClimbResponse)
            .toList();
        List<FeedbackDto> recentFeedback = feedbackRepository.findTop5ByClimberIdOrderByCreatedAtDesc(requiredClimberId)
            .stream()
            .map(feedback -> FeedbackDto.builder()
                .id(feedback.getId())
                .climbLogId(feedback.getClimbLog().getId())
                .routeName(feedback.getClimbLog().getRouteName())
                .difficulty(feedback.getClimbLog().getDifficulty())
                .venue(feedback.getClimbLog().getVenue())
                .climbDate(feedback.getClimbLog().getDate())
                .climbStatus(feedback.getClimbLog().getStatus())
                .coachId(feedback.getCoach().getId())
                .coachName(feedback.getCoach().getName())
                .climberId(feedback.getClimber().getId())
                .climberName(feedback.getClimber().getName())
                .comment(feedback.getComment())
                .rating(feedback.getRating())
                .createdAt(feedback.getCreatedAt())
                .build())
            .toList();

        ClimberDetailDto data = ClimberDetailDto.builder()
            .id(climber.getId())
            .name(climber.getName())
            .email(climber.getEmail())
            .climbCount(climbLogRepository.countByUserId(requiredClimberId))
            .completedCount(climbLogRepository.countByUserIdAndStatus(requiredClimberId, ClimbStatus.COMPLETED))
            .attemptedCount(climbLogRepository.countByUserIdAndStatus(requiredClimberId, ClimbStatus.ATTEMPTED))
            .feedbackCount(feedbackRepository.countByClimberId(requiredClimberId))
            .recentClimbs(recentClimbs)
            .recentFeedback(recentFeedback)
            .build();

        return ApiResponse.success("Climber detail loaded.", data);
    }

    private ClimberOverviewDto toClimberOverview(User user, Map<Long, Long> climbCounts, Map<Long, Long> feedbackCounts) {
        return ClimberOverviewDto.builder()
            .id(user.getId())
            .name(user.getName())
            .email(user.getEmail())
            .climbCount(climbCounts.getOrDefault(user.getId(), 0L))
            .feedbackCount(feedbackCounts.getOrDefault(user.getId(), 0L))
            .build();
    }

    private List<Long> extractUserIds(List<User> users) {
        return users.stream().map(User::getId).toList();
    }

    private Map<Long, Long> loadClimbCounts(List<User> users) {
        List<Long> userIds = extractUserIds(users);
        return userIds.isEmpty() ? Map.of() : toCountMap(climbLogRepository.countByUserIds(userIds));
    }

    private Map<Long, Long> loadFeedbackCounts(List<User> users) {
        List<Long> userIds = extractUserIds(users);
        return userIds.isEmpty() ? Map.of() : toCountMap(feedbackRepository.countByClimberIds(userIds));
    }

    private Map<Long, Long> toCountMap(List<UserCountProjection> counts) {
        return counts.stream().collect(Collectors.toMap(UserCountProjection::getUserId, UserCountProjection::getTotal));
    }

    private ClimbLogResponse toClimbResponse(ClimbLog climbLog) {
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
