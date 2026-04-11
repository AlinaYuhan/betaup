package com.betaup.dto.session;

import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SessionDto {
    private Long id;
    private Long userId;
    private String venue;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private boolean active; // endTime == null
}
