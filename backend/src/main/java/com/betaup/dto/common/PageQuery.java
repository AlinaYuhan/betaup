package com.betaup.dto.common;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageQuery {

    @Min(0)
    private Integer page = 0;

    @Min(1)
    @Max(50)
    private Integer size = 6;

    private String sortBy;

    @Pattern(regexp = "(?i)asc|desc")
    private String sortDir = "desc";
}
