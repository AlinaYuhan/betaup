package com.betaup.service;

import com.betaup.dto.auth.AuthResponse;
import com.betaup.dto.auth.LoginRequest;
import com.betaup.dto.auth.RegisterRequest;
import com.betaup.dto.auth.UpdateProfileRequest;
import com.betaup.dto.auth.UserProfileDto;
import com.betaup.dto.common.ApiResponse;

public interface AuthService {

    ApiResponse<String> getStatus();

    ApiResponse<AuthResponse> login(LoginRequest request);

    ApiResponse<AuthResponse> register(RegisterRequest request);

    ApiResponse<UserProfileDto> getCurrentUserProfile();

    ApiResponse<UserProfileDto> updateProfile(UpdateProfileRequest request);
}
