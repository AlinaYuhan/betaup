package com.betaup.controller;

import com.betaup.dto.climb.ClimbLogRequest;
import com.betaup.dto.climb.ClimbLogResponse;
import com.betaup.dto.climb.GradeStatDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import java.util.List;
import com.betaup.service.ClimbService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ModelAttribute;

@RestController
@RequestMapping("/api/climbs")
@RequiredArgsConstructor
public class ClimbController {

    private final ClimbService climbService;

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<String>> status() {
        return ResponseEntity.ok(climbService.getStatus());
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ClimbLogResponse>>> getClimbs(
        @Valid @ModelAttribute PageQuery pageQuery
    ) {
        return ResponseEntity.ok(climbService.getClimbLogs(pageQuery));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ClimbLogResponse>> getClimb(@PathVariable Long id) {
        return ResponseEntity.ok(climbService.getClimbLog(id));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ClimbLogResponse>> createClimb(@Valid @RequestBody ClimbLogRequest request) {
        return ResponseEntity.ok(climbService.createClimbLog(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ClimbLogResponse>> updateClimb(
        @PathVariable Long id,
        @Valid @RequestBody ClimbLogRequest request
    ) {
        return ResponseEntity.ok(climbService.updateClimbLog(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteClimb(@PathVariable Long id) {
        return ResponseEntity.ok(climbService.deleteClimbLog(id));
    }

    @GetMapping("/grade-stats")
    public ResponseEntity<ApiResponse<List<GradeStatDto>>> getGradeStats() {
        return ResponseEntity.ok(climbService.getGradeStats());
    }
}
