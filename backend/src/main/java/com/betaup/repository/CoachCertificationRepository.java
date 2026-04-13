package com.betaup.repository;

import com.betaup.entity.CertificationStatus;
import com.betaup.entity.CoachCertification;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CoachCertificationRepository extends JpaRepository<CoachCertification, Long> {

    Optional<CoachCertification> findTopByUserIdOrderByAppliedAtDesc(Long userId);

    List<CoachCertification> findByStatusOrderByAppliedAtAsc(CertificationStatus status);
}
