package com.betaup.controller;

import com.betaup.dto.auth.AuthResponse;
import com.betaup.dto.auth.LoginRequest;
import com.betaup.dto.auth.RegisterRequest;
import com.betaup.dto.auth.UpdateProfileRequest;
import com.betaup.dto.auth.UserProfileDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @GetMapping("/status")
    public ResponseEntity<ApiResponse<String>> status() {
        return ResponseEntity.ok(authService.getStatus());
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.ok(authService.register(request));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserProfileDto>> me() {
        return ResponseEntity.ok(authService.getCurrentUserProfile());
    }

    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileDto>> updateProfile(
        @Valid @RequestBody UpdateProfileRequest request
    ) {
        return ResponseEntity.ok(authService.updateProfile(request));
    }
}
