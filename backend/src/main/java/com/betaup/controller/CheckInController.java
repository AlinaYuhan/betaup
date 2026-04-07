package com.betaup.controller;

import com.betaup.dto.checkin.CheckInRequest;
import com.betaup.dto.checkin.CheckInResult;
import com.betaup.dto.common.ApiResponse;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.CheckInService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/checkins")
@RequiredArgsConstructor
public class CheckInController {

    private final CheckInService checkInService;
    private final CurrentUserService currentUserService;

    @PostMapping
    public ResponseEntity<ApiResponse<CheckInResult>> checkIn(@RequestBody CheckInRequest request) {
        Long userId = currentUserService.getCurrentUser().getId();
        return ResponseEntity.ok(checkInService.checkIn(userId, request));
    }
}
