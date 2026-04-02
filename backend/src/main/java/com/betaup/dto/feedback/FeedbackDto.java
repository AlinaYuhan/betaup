package com.betaup.dto.feedback;

import com.betaup.entity.ClimbStatus;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeedbackDto {

    private Long id;
    private Long climbLogId;
    private String routeName;
    private String difficulty;
    private String venue;
    private LocalDate climbDate;
    private ClimbStatus climbStatus;
    private Long coachId;
    private String coachName;
    private Long climberId;
    private String climberName;
    private String comment;
    private Integer rating;
    private LocalDateTime createdAt;
}
