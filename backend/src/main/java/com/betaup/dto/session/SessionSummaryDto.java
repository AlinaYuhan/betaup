package com.betaup.dto.session;

import com.betaup.dto.climb.GradeStatDto;
import java.time.LocalDateTime;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SessionSummaryDto {
    private Long sessionId;
    private String venue;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private int durationMinutes;
    private int totalLogs;
    private int flashes;
    private int sends;
    private int attempts;
    private String hardestSend; // highest V-grade that was sent/flashed
    private List<GradeStatDto> gradeSummary;
}
