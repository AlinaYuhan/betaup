package com.betaup.service.impl;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import com.betaup.dto.feedback.CreateFeedbackRequest;
import com.betaup.dto.feedback.FeedbackDto;
import com.betaup.dto.feedback.UpdateFeedbackRequest;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.Feedback;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.exception.ResourceNotFoundException;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.UserRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import com.betaup.service.FeedbackService;
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
public class FeedbackServiceImpl implements FeedbackService {

    private final FeedbackRepository feedbackRepository;
    private final ClimbLogRepository climbLogRepository;
    private final UserRepository userRepository;
    private final CurrentUserService currentUserService;
    private final BadgeAutomationService badgeAutomationService;

    @Override
    public ApiResponse<String> getStatus() {
        return ApiResponse.success("Feedback module is live.", "FEEDBACK_READY");
    }

    @Override
    public ApiResponse<PageResponse<FeedbackDto>> getMyFeedback(Long climberId, Integer rating, PageQuery pageQuery) {
        User currentUser = currentUserService.getCurrentUser();
        Pageable pageable = PageableFactory.create(
            pageQuery,
            6,
            "createdAt",
            Sort.Direction.DESC,
            Map.of(
                "createdAt", "createdAt",
                "rating", "rating"
            )
        );
        Page<FeedbackDto> history = (currentUser.getRole() == UserRole.COACH
                ? feedbackRepository.findCoachHistory(currentUser.getId(), climberId, rating, pageable)
                : feedbackRepository.findClimberHistory(currentUser.getId(), rating, pageable))
            .map(this::toDto);

        return ApiResponse.success("Feedback history loaded.", PageResponse.from(history));
    }

    @Override
    public ApiResponse<FeedbackDto> getFeedbackById(Long feedbackId) {
        User currentUser = currentUserService.getCurrentUser();
        Feedback feedback = feedbackRepository.findById(feedbackId)
            .orElseThrow(() -> new ResourceNotFoundException("Feedback not found."));

        boolean allowed = currentUser.getRole() == UserRole.COACH
            ? feedback.getCoach().getId().equals(currentUser.getId())
            : feedback.getClimber().getId().equals(currentUser.getId());
        if (!allowed) {
            throw new AccessDeniedException("You do not have access to this feedback.");
        }

        return ApiResponse.success("Feedback loaded.", toDto(feedback));
    }

    @Override
    @Transactional
    public ApiResponse<FeedbackDto> createFeedback(CreateFeedbackRequest request) {
        User coach = currentUserService.requireRole(UserRole.COACH);
        User climber = userRepository.findById(request.getClimberId())
            .orElseThrow(() -> new ResourceNotFoundException("Climber not found."));
        if (climber.getRole() != UserRole.CLIMBER) {
            throw new IllegalArgumentException("Feedback can only be created for a climber account.");
        }

        ClimbLog climbLog = climbLogRepository.findById(request.getClimbLogId())
            .orElseThrow(() -> new ResourceNotFoundException("Climb log not found."));
        if (!climbLog.getUser().getId().equals(climber.getId())) {
            throw new AccessDeniedException("Selected climb log does not belong to the selected climber.");
        }

        Feedback feedback = feedbackRepository.save(
            Feedback.builder()
                .climbLog(climbLog)
                .coach(coach)
                .climber(climber)
                .comment(request.getComment().trim())
                .rating(request.getRating())
                .build()
        );
        badgeAutomationService.evaluateUserBadges(climber);

        return ApiResponse.success("Feedback created.", toDto(feedback));
    }

    @Override
    @Transactional
    public ApiResponse<FeedbackDto> updateFeedback(Long feedbackId, UpdateFeedbackRequest request) {
        Feedback feedback = findOwnedCoachFeedback(feedbackId);
        feedback.setComment(request.getComment().trim());
        feedback.setRating(request.getRating());

        return ApiResponse.success("Feedback updated.", toDto(feedback));
    }

    @Override
    @Transactional
    public ApiResponse<Void> deleteFeedback(Long feedbackId) {
        Feedback feedback = findOwnedCoachFeedback(feedbackId);
        feedbackRepository.delete(feedback);
        return ApiResponse.success("Feedback deleted.", null);
    }

    private Feedback findOwnedCoachFeedback(Long feedbackId) {
        User coach = currentUserService.requireRole(UserRole.COACH);
        Feedback feedback = feedbackRepository.findById(feedbackId)
            .orElseThrow(() -> new ResourceNotFoundException("Feedback not found."));
        if (!feedback.getCoach().getId().equals(coach.getId())) {
            throw new AccessDeniedException("You can only manage feedback created by your own account.");
        }
        return feedback;
    }

    private FeedbackDto toDto(Feedback feedback) {
        return FeedbackDto.builder()
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
            .build();
    }
}
