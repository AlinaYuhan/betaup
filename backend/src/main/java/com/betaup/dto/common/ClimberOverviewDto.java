package com.betaup.dto.common;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClimberOverviewDto {

    private Long id;
    private String name;
    private String email;
    private long climbCount;
    private long feedbackCount;
}
