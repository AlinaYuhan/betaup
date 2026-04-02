package com.betaup.dto.climb;

import com.betaup.entity.ClimbStatus;
import jakarta.validation.constraints.NotBlank;
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

    @NotBlank
    @Size(max = 160)
    private String routeName;

    @NotBlank
    @Size(max = 64)
    private String difficulty;

    @NotNull
    private LocalDate date;

    @NotBlank
    @Size(max = 120)
    private String venue;

    @NotNull
    private ClimbStatus status;

    @Size(max = 1000)
    private String notes;
}
