package com.betaup.service;

import com.betaup.dto.climb.ClimbLogRequest;
import com.betaup.dto.climb.ClimbLogResponse;
import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;

public interface ClimbService {

    ApiResponse<String> getStatus();

    ApiResponse<PageResponse<ClimbLogResponse>> getClimbLogs(PageQuery pageQuery);

    ApiResponse<ClimbLogResponse> getClimbLog(Long climbLogId);

    ApiResponse<ClimbLogResponse> createClimbLog(ClimbLogRequest request);

    ApiResponse<ClimbLogResponse> updateClimbLog(Long climbLogId, ClimbLogRequest request);

    ApiResponse<Void> deleteClimbLog(Long climbLogId);
}
