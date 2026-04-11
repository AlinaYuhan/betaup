package com.betaup.dto.climb;

import com.betaup.entity.ClimbResult;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClimbLogRequest {

    @Size(max = 160)
    private String routeName;

    @Size(max = 64)
    private String difficulty;

    @NotNull
    private LocalDate date;

    @Size(max = 120)
    private String venue;

    private ClimbResult result;

    private Integer attempts;

    private Long sessionId;

    @Size(max = 1000)
    private String notes;
}
