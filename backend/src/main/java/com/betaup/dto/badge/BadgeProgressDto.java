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
public class BadgeProgressDto {

    private Long badgeId;
    private String badgeKey;
    private String name;
    private String description;
    private BadgeCriteriaType criteriaType;
    private String category;
    private Integer threshold;
    private Integer currentValue;
    private boolean earned;
    private LocalDateTime awardedAt;
}
