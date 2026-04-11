package com.betaup.dto.climb;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GradeStatDto {
    private String difficulty;
    private long total;
    private long sends;   // FLASH + SEND
    private long flashes; // FLASH only
}
