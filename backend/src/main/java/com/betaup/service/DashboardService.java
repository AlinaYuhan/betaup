package com.betaup.service;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.dashboard.DashboardRange;
import com.betaup.dto.dashboard.DashboardSummaryDto;

public interface DashboardService {

    ApiResponse<DashboardSummaryDto> getDashboardSummary(DashboardRange range);

    String exportDashboardSummary(DashboardRange range);
}
