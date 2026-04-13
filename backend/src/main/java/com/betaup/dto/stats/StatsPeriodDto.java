package com.betaup.dto.stats;

import com.betaup.dto.climb.GradeStatDto;
import java.util.List;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class StatsPeriodDto {
    private String period;                      // WEEK | MONTH | ALL
    private List<StatsBucketDto> buckets;
    private List<GradeStatDto> gradeDistribution;
    private StatsSummaryDto summary;
}
