package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.stats.StatsPeriodDto;
import com.betaup.entity.User;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.StatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/stats")
@RequiredArgsConstructor
public class StatsController {

    private final StatsService statsService;
    private final CurrentUserService currentUserService;

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<StatsPeriodDto>> getMyStats(
        @RequestParam(defaultValue = "WEEK") String period
    ) {
        User user = currentUserService.getCurrentUser();
        StatsPeriodDto stats = statsService.getStats(user, period);
        return ResponseEntity.ok(ApiResponse.success("Stats loaded.", stats));
    }
}
