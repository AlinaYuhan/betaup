package com.betaup.controller;

import com.betaup.dto.climb.ClimbLogResponse;
import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.common.PageResponse;
import com.betaup.dto.session.SessionDto;
import com.betaup.dto.session.SessionStartRequest;
import com.betaup.dto.session.SessionSummaryDto;
import com.betaup.service.ClimbService;
import com.betaup.service.SessionService;
import java.util.List;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/sessions")
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;
    private final ClimbService climbService;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<SessionSummaryDto>>> getSessions(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size
    ) {
        return ResponseEntity.ok(sessionService.getUserSessions(page, size));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<SessionDto>> startSession(
        @Valid @RequestBody SessionStartRequest request
    ) {
        return ResponseEntity.ok(sessionService.startSession(request));
    }

    @GetMapping("/active")
    public ResponseEntity<ApiResponse<SessionDto>> getActive() {
        return ResponseEntity.ok(sessionService.getActiveSession());
    }

    @PostMapping("/{id}/end")
    public ResponseEntity<ApiResponse<SessionSummaryDto>> endSession(@PathVariable Long id) {
        return ResponseEntity.ok(sessionService.endSession(id));
    }

    @GetMapping("/{id}/climbs")
    public ResponseEntity<ApiResponse<List<ClimbLogResponse>>> getSessionClimbs(@PathVariable Long id) {
        return ResponseEntity.ok(climbService.getClimbsBySession(id));
    }
}
