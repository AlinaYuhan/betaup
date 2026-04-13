package com.betaup.dto.coach;

import com.betaup.entity.CertificationStatus;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CoachStatusDto {
    private boolean isCoachCertified;
    private CertificationStatus certificationStatus;  // null = never applied
    private String rejectReason;
    private LocalDateTime appliedAt;
    private LocalDateTime reviewedAt;
}
