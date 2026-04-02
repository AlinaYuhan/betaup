package com.betaup.service;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.ClimberDetailDto;
import com.betaup.dto.common.ClimberOverviewDto;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import java.util.List;

public interface CoachService {

    ApiResponse<String> getStatus();

    ApiResponse<PageResponse<ClimberOverviewDto>> getClimbersOverview(String query, PageQuery pageQuery);

    ApiResponse<List<ClimberOverviewDto>> getClimberOptions();

    ApiResponse<ClimberDetailDto> getClimberDetail(Long climberId);
}
