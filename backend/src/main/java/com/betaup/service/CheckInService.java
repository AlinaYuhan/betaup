package com.betaup.service;

import com.betaup.dto.checkin.CheckInRequest;
import com.betaup.dto.checkin.CheckInResult;
import com.betaup.dto.common.ApiResponse;

public interface CheckInService {

    ApiResponse<CheckInResult> checkIn(Long userId, CheckInRequest request);
}
