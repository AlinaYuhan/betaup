package com.betaup.dto.stats;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class StatsBucketDto {
    private String label;        // e.g. "4/7" (week) or "4月" (month)
    private int climbCount;
    private int flashCount;
    private int sendCount;
    private int attemptCount;
}
