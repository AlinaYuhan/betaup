package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.dashboard.DashboardRange;
import com.betaup.dto.dashboard.DashboardSummaryDto;
import com.betaup.service.DashboardService;
import java.nio.charset.StandardCharsets;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping
    public ResponseEntity<ApiResponse<DashboardSummaryDto>> getDashboard(
        @RequestParam(defaultValue = "LAST_180_DAYS") DashboardRange range
    ) {
        return ResponseEntity.ok(dashboardService.getDashboardSummary(range));
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportDashboard(
        @RequestParam(defaultValue = "LAST_180_DAYS") DashboardRange range
    ) {
        String exportBody = dashboardService.exportDashboardSummary(range);
        String fileName = "betaup-dashboard-" + range.name().toLowerCase() + ".csv";

        return ResponseEntity.ok()
            .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + fileName + "\"")
            .contentType(new MediaType("text", "csv", StandardCharsets.UTF_8))
            .body(exportBody.getBytes(StandardCharsets.UTF_8));
    }
}
