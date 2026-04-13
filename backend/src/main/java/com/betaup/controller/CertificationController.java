package com.betaup.controller;

import com.betaup.dto.coach.CertificationReviewDto;
import com.betaup.dto.coach.CoachStatusDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.entity.User;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.CoachCertificationService;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/certification")
@RequiredArgsConstructor
public class CertificationController {

    private final CoachCertificationService certService;
    private final CurrentUserService currentUserService;

    // ── User-facing ────────────────────────────────────────────────────────────

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<CoachStatusDto>> getStatus() {
        User user = currentUserService.getCurrentUser();
        return ResponseEntity.ok(ApiResponse.success("Status loaded.", certService.getStatus(user)));
    }

    @PostMapping("/apply")
    public ResponseEntity<ApiResponse<Void>> apply(
        @RequestParam("image") MultipartFile image,
        @RequestParam(value = "resumeText", required = false, defaultValue = "") String resumeText
    ) {
        User user = currentUserService.getCurrentUser();
        certService.apply(user, image, resumeText);
        return ResponseEntity.ok(ApiResponse.success("Application submitted.", null));
    }

    // ── Admin-facing ───────────────────────────────────────────────────────────

    @GetMapping("/admin/pending")
    public ResponseEntity<ApiResponse<List<CertificationReviewDto>>> getPending() {
        // Role check is enforced by SecurityConfig — only ADMIN can reach this
        return ResponseEntity.ok(ApiResponse.success("Pending loaded.", certService.getPendingApplications()));
    }

    @PostMapping("/admin/{id}/approve")
    public ResponseEntity<ApiResponse<Void>> approve(@PathVariable Long id) {
        certService.approve(id);
        return ResponseEntity.ok(ApiResponse.success("Approved.", null));
    }

    @PostMapping("/admin/{id}/reject")
    public ResponseEntity<ApiResponse<Void>> reject(
        @PathVariable Long id,
        @RequestBody Map<String, String> body
    ) {
        String reason = body.getOrDefault("rejectReason", "未说明原因");
        certService.reject(id, reason);
        return ResponseEntity.ok(ApiResponse.success("Rejected.", null));
    }
}
