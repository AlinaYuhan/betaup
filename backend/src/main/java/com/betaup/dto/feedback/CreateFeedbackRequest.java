package com.betaup.dto.feedback;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateFeedbackRequest {

    @NotNull
    private Long climbLogId;

    @NotNull
    private Long climberId;

    @NotBlank
    @Size(max = 1000)
    private String comment;

    @NotNull
    @Min(1)
    @Max(5)
    private Integer rating;
}
