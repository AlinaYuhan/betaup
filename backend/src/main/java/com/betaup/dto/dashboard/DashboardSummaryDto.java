package com.betaup.dto.dashboard;

import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DashboardSummaryDto {

    private String audience;
    private DashboardRange range;
    private String rangeLabel;
    private String title;
    private String summary;
    private List<DashboardMetricDto> metrics;
    private List<DashboardBreakdownItemDto> breakdown;
    private List<DashboardChartDto> charts;
    private List<DashboardActivityDto> recentActivity;
    private List<String> highlights;
}
