package com.betaup.dto.badge;

import com.betaup.entity.BadgeCriteriaType;
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
public class UpdateBadgeRuleRequest {

    @NotBlank
    @Size(max = 120)
    private String name;

    @NotBlank
    @Size(max = 500)
    private String description;

    @NotNull
    @Min(1)
    private Integer threshold;

    @NotNull
    private BadgeCriteriaType criteriaType;
}
