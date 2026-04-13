package com.betaup.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "coach_certifications",
    indexes = {
        @Index(name = "idx_coach_cert_user", columnList = "user_id"),
        @Index(name = "idx_coach_cert_status", columnList = "status")
    }
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CoachCertification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CertificationStatus status;

    @Size(max = 500)
    @Column(length = 500)
    private String certificateImagePath;

    @Size(max = 2000)
    @Column(length = 2000)
    private String resumeText;

    @Size(max = 500)
    @Column(length = 500)
    private String rejectReason;

    @Column(nullable = false)
    private LocalDateTime appliedAt;

    @Column
    private LocalDateTime reviewedAt;
}
