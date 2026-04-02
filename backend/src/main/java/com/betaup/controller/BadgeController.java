package com.betaup.controller;

import com.betaup.dto.badge.BadgeDto;
import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.dto.badge.CreateBadgeRuleRequest;
import com.betaup.dto.badge.UpdateBadgeRuleRequest;
import com.betaup.dto.badge.UserBadgeDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.service.BadgeService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/badges")
@RequiredArgsConstructor
public class BadgeController {

    private final BadgeService badgeService;

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<String>> status() {
        return ResponseEntity.ok(badgeService.getStatus());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BadgeDto>>> getBadges() {
        return ResponseEntity.ok(badgeService.getBadges());
    }

    @GetMapping("/rules")
    public ResponseEntity<ApiResponse<List<BadgeDto>>> getBadgeRules() {
        return ResponseEntity.ok(badgeService.getBadgeRules());
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<List<UserBadgeDto>>> getMyBadges() {
        return ResponseEntity.ok(badgeService.getMyBadges());
    }

    @GetMapping("/progress")
    public ResponseEntity<ApiResponse<List<BadgeProgressDto>>> getMyBadgeProgress() {
        return ResponseEntity.ok(badgeService.getMyBadgeProgress());
    }

    @PostMapping("/rules")
    public ResponseEntity<ApiResponse<BadgeDto>> createBadgeRule(@Valid @RequestBody CreateBadgeRuleRequest request) {
        return ResponseEntity.ok(badgeService.createBadgeRule(request));
    }

    @PutMapping("/rules/{id}")
    public ResponseEntity<ApiResponse<BadgeDto>> updateBadgeRule(
        @PathVariable Long id,
        @Valid @RequestBody UpdateBadgeRuleRequest request
    ) {
        return ResponseEntity.ok(badgeService.updateBadgeRule(id, request));
    }

    @DeleteMapping("/rules/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBadgeRule(@PathVariable Long id) {
        return ResponseEntity.ok(badgeService.deleteBadgeRule(id));
    }
}
