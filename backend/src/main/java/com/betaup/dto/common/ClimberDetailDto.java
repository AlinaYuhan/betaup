package com.betaup.dto.common;

import com.betaup.dto.climb.ClimbLogResponse;
import com.betaup.dto.feedback.FeedbackDto;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClimberDetailDto {

    private Long id;
    private String name;
    private String email;
    private long climbCount;
    private long completedCount;
    private long attemptedCount;
    private long feedbackCount;
    private List<ClimbLogResponse> recentClimbs;
    private List<FeedbackDto> recentFeedback;
}
