package com.betaup.service;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageResponse;
import com.betaup.dto.session.SessionDto;
import com.betaup.dto.session.SessionStartRequest;
import com.betaup.dto.session.SessionSummaryDto;

public interface SessionService {

    ApiResponse<SessionDto> startSession(SessionStartRequest request);

    ApiResponse<SessionDto> getActiveSession();

    ApiResponse<SessionSummaryDto> endSession(Long sessionId);

    ApiResponse<PageResponse<SessionSummaryDto>> getUserSessions(int page, int size);
}
