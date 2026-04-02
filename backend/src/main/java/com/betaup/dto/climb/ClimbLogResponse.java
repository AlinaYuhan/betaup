package com.betaup.dto.climb;

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
public class ClimbLogResponse {

    private Long id;
    private Long userId;
    private String routeName;
    private String difficulty;
    private LocalDate date;
    private String venue;
    private ClimbStatus status;
    private String notes;
    private LocalDateTime createdAt;
}
