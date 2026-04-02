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
public class DashboardChartDto {

    private String title;
    private String subtitle;
    private String format;
    private List<DashboardChartPointDto> points;
}
