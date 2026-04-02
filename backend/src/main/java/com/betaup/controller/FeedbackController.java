package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import com.betaup.dto.feedback.CreateFeedbackRequest;
import com.betaup.dto.feedback.FeedbackDto;
import com.betaup.dto.feedback.UpdateFeedbackRequest;
import com.betaup.service.FeedbackService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ModelAttribute;

@RestController
@RequestMapping("/api/feedback")
@RequiredArgsConstructor
public class FeedbackController {

    private final FeedbackService feedbackService;

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<String>> status() {
        return ResponseEntity.ok(feedbackService.getStatus());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<FeedbackDto>>> getFeedback(
        @RequestParam(required = false) Long climberId,
        @RequestParam(required = false) Integer rating,
        @Valid @ModelAttribute PageQuery pageQuery
    ) {
        return ResponseEntity.ok(feedbackService.getMyFeedback(climberId, rating, pageQuery));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<FeedbackDto>> getFeedbackById(@PathVariable Long id) {
        return ResponseEntity.ok(feedbackService.getFeedbackById(id));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<FeedbackDto>> createFeedback(@Valid @RequestBody CreateFeedbackRequest request) {
        return ResponseEntity.ok(feedbackService.createFeedback(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<FeedbackDto>> updateFeedback(
        @PathVariable Long id,
        @Valid @RequestBody UpdateFeedbackRequest request
    ) {
        return ResponseEntity.ok(feedbackService.updateFeedback(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteFeedback(@PathVariable Long id) {
        return ResponseEntity.ok(feedbackService.deleteFeedback(id));
    }
}
