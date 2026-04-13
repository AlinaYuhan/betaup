package com.betaup.dto.stats;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class StatsSummaryDto {
    private int totalClimbs;
    private int totalFlashes;
    private int totalSends;
    private int totalAttempts;
    private int flashRatePct;   // integer percentage, e.g. 17
    private int totalSessions;
    private String topGrade;    // null if no completed climbs
}
