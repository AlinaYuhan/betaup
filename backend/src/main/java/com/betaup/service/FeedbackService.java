package com.betaup.service;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import com.betaup.dto.feedback.CreateFeedbackRequest;
import com.betaup.dto.feedback.FeedbackDto;
import com.betaup.dto.feedback.UpdateFeedbackRequest;

public interface FeedbackService {

    ApiResponse<String> getStatus();

    ApiResponse<PageResponse<FeedbackDto>> getMyFeedback(Long climberId, Integer rating, PageQuery pageQuery);

    ApiResponse<FeedbackDto> getFeedbackById(Long feedbackId);

    ApiResponse<FeedbackDto> createFeedback(CreateFeedbackRequest request);

    ApiResponse<FeedbackDto> updateFeedback(Long feedbackId, UpdateFeedbackRequest request);

    ApiResponse<Void> deleteFeedback(Long feedbackId);
}
