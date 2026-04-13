package com.betaup.service;

import com.betaup.dto.coach.CertificationReviewDto;
import com.betaup.dto.coach.CoachStatusDto;
import com.betaup.entity.User;
import java.util.List;
import org.springframework.web.multipart.MultipartFile;

public interface CoachCertificationService {

    CoachStatusDto getStatus(User user);

    void apply(User user, MultipartFile image, String resumeText);

    void approve(Long certificationId);

    void reject(Long certificationId, String rejectReason);

    List<CertificationReviewDto> getPendingApplications();
}
