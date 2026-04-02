package com.betaup.dto.badge;

import com.betaup.entity.BadgeCriteriaType;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BadgeDto {

    private Long id;
    private String badgeKey;
    private String name;
    private String description;
    private Integer threshold;
    private BadgeCriteriaType criteriaType;
    private LocalDateTime createdAt;
}
