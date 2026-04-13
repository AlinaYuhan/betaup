package com.betaup.dto.coach;

import com.betaup.entity.CertificationStatus;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CertificationReviewDto {
    private Long certificationId;
    private Long userId;
    private String userName;
    private String userEmail;
    private CertificationStatus status;
    private String certificateImageUrl;
    private String resumeText;
    private String rejectReason;
    private LocalDateTime appliedAt;
}
