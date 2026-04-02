package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.ClimberDetailDto;
import com.betaup.dto.common.ClimberOverviewDto;
import com.betaup.dto.common.PageQuery;
import com.betaup.dto.common.PageResponse;
import com.betaup.service.CoachService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/coach")
@RequiredArgsConstructor
public class CoachController {

    private final CoachService coachService;

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<String>> status() {
        return ResponseEntity.ok(coachService.getStatus());
    }

    @GetMapping("/climbers")
    public ResponseEntity<ApiResponse<PageResponse<ClimberOverviewDto>>> getClimbers(
        @RequestParam(required = false, name = "q") String query,
        @Valid @ModelAttribute PageQuery pageQuery
    ) {
        return ResponseEntity.ok(coachService.getClimbersOverview(query, pageQuery));
    }

    @GetMapping("/climbers/options")
    public ResponseEntity<ApiResponse<List<ClimberOverviewDto>>> getClimberOptions() {
        return ResponseEntity.ok(coachService.getClimberOptions());
    }

    @GetMapping("/climbers/{id}")
    public ResponseEntity<ApiResponse<ClimberDetailDto>> getClimberDetail(@PathVariable Long id) {
        return ResponseEntity.ok(coachService.getClimberDetail(id));
    }
}
