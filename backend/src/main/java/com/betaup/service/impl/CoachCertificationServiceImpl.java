package com.betaup.service.impl;

import com.betaup.dto.coach.CertificationReviewDto;
import com.betaup.dto.coach.CoachStatusDto;
import com.betaup.entity.CertificationStatus;
import com.betaup.entity.CoachCertification;
import com.betaup.entity.Notification;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.repository.CoachCertificationRepository;
import com.betaup.repository.NotificationRepository;
import com.betaup.repository.UserRepository;
import com.betaup.service.CoachCertificationService;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class CoachCertificationServiceImpl implements CoachCertificationService {

    private final CoachCertificationRepository certRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;

    @Value("${app.upload.dir}")
    private String uploadDir;

    @Override
    @Transactional(readOnly = true)
    public CoachStatusDto getStatus(User user) {
        return certRepository.findTopByUserIdOrderByAppliedAtDesc(user.getId())
            .map(cert -> CoachStatusDto.builder()
                .isCoachCertified(user.isCoachCertified())
                .certificationStatus(cert.getStatus())
                .rejectReason(cert.getRejectReason())
                .appliedAt(cert.getAppliedAt())
                .reviewedAt(cert.getReviewedAt())
                .build())
            .orElse(CoachStatusDto.builder()
                .isCoachCertified(user.isCoachCertified())
                .certificationStatus(null)
                .build());
    }

    @Override
    @Transactional
    public void apply(User user, MultipartFile image, String resumeText) {
        // Check for existing pending application
        certRepository.findTopByUserIdOrderByAppliedAtDesc(user.getId()).ifPresent(existing -> {
            if (existing.getStatus() == CertificationStatus.PENDING) {
                throw new IllegalStateException("Already has a pending application.");
            }
        });

        String imagePath = saveImage(image);

        CoachCertification cert = CoachCertification.builder()
            .user(user)
            .status(CertificationStatus.PENDING)
            .certificateImagePath(imagePath)
            .resumeText(resumeText)
            .appliedAt(LocalDateTime.now())
            .build();
        certRepository.save(cert);
    }

    @Override
    @Transactional
    public void approve(Long certificationId) {
        CoachCertification cert = certRepository.findById(certificationId)
            .orElseThrow(() -> new IllegalArgumentException("Certification not found."));
        cert.setStatus(CertificationStatus.APPROVED);
        cert.setReviewedAt(LocalDateTime.now());
        certRepository.save(cert);

        User user = cert.getUser();
        user.setCoachCertified(true);
        user.setRole(UserRole.COACH);
        userRepository.save(user);

        notificationRepository.save(Notification.builder()
            .recipient(user)
            .type("SYSTEM")
            .actorId(0L)
            .actorName("BetaUp")
            .referenceId(cert.getId())
            .content("🎉 恭喜！你的教练认证已通过审核，你现在是认证教练了！")
            .isRead(false)
            .build());
    }

    @Override
    @Transactional
    public void reject(Long certificationId, String rejectReason) {
        CoachCertification cert = certRepository.findById(certificationId)
            .orElseThrow(() -> new IllegalArgumentException("Certification not found."));
        cert.setStatus(CertificationStatus.REJECTED);
        cert.setRejectReason(rejectReason);
        cert.setReviewedAt(LocalDateTime.now());
        certRepository.save(cert);

        notificationRepository.save(Notification.builder()
            .recipient(cert.getUser())
            .type("SYSTEM")
            .actorId(0L)
            .actorName("BetaUp")
            .referenceId(cert.getId())
            .content("📋 你的教练认证申请未通过：" + rejectReason)
            .isRead(false)
            .build());
    }

    @Override
    @Transactional(readOnly = true)
    public List<CertificationReviewDto> getPendingApplications() {
        return certRepository.findByStatusOrderByAppliedAtAsc(CertificationStatus.PENDING)
            .stream()
            .map(this::toReviewDto)
            .toList();
    }

    // ── private ────────────────────────────────────────────────────────────────

    private String saveImage(MultipartFile image) {
        validateImageType(image);
        try {
            Path dir = Paths.get(uploadDir, "certificates");
            Files.createDirectories(dir);
            String ext = getExtension(image.getOriginalFilename());
            String filename = UUID.randomUUID() + ext;
            Files.copy(image.getInputStream(), dir.resolve(filename));
            return "certificates/" + filename;
        } catch (IOException e) {
            throw new RuntimeException("Failed to save certificate image.", e);
        }
    }

    private void validateImageType(MultipartFile file) {
        String ct = file.getContentType();
        if (ct == null || !java.util.List.of("image/jpeg", "image/png", "image/webp").contains(ct)) {
            throw new IllegalArgumentException("Only JPEG, PNG, or WebP images are accepted.");
        }
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return ".jpg";
        return filename.substring(filename.lastIndexOf('.'));
    }

    private CertificationReviewDto toReviewDto(CoachCertification cert) {
        User user = cert.getUser();
        return CertificationReviewDto.builder()
            .certificationId(cert.getId())
            .userId(user.getId())
            .userName(user.getName())
            .userEmail(user.getEmail())
            .status(cert.getStatus())
            .certificateImageUrl("/uploads/" + cert.getCertificateImagePath())
            .resumeText(cert.getResumeText())
            .rejectReason(cert.getRejectReason())
            .appliedAt(cert.getAppliedAt())
            .build();
    }
}
