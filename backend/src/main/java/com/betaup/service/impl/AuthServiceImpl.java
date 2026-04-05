package com.betaup.service.impl;

import com.betaup.dto.auth.AuthResponse;
import com.betaup.dto.auth.LoginRequest;
import com.betaup.dto.auth.RegisterRequest;
import com.betaup.dto.auth.UserProfileDto;
import com.betaup.dto.common.ApiResponse;
import com.betaup.entity.User;
import com.betaup.exception.ConflictException;
import com.betaup.repository.UserRepository;
import com.betaup.security.jwt.JwtTokenProvider;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.AuthService;
import java.util.Objects;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final CurrentUserService currentUserService;

    @Override
    public ApiResponse<String> getStatus() {
        return ApiResponse.success("Auth module is live.", "AUTH_READY");
    }

    @Override
    @Transactional
    public ApiResponse<AuthResponse> login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmailIgnoreCase(email)
            .orElseThrow(() -> new IllegalArgumentException("Invalid email or password."));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password.");
        }

        return ApiResponse.success("Login successful.", buildAuthResponse(user));
    }

    @Override
    @Transactional
    public ApiResponse<AuthResponse> register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException("An account with this email already exists.");
        }

        User userToCreate = User.builder()
            .name(request.getName().trim())
            .email(email)
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .role(request.getRole())
            .build();
        User user = userRepository.save(
            Objects.requireNonNull(userToCreate, "user must not be null")
        );

        return ApiResponse.success("Registration successful.", buildAuthResponse(user));
    }

    @Override
    public ApiResponse<UserProfileDto> getCurrentUserProfile() {
        return ApiResponse.success("Current user loaded.", toUserProfile(currentUserService.getCurrentUser()));
    }

    private AuthResponse buildAuthResponse(User user) {
        return AuthResponse.builder()
            .user(toUserProfile(user))
            .token(jwtTokenProvider.generateToken(user.getEmail()))
            .build();
    }

    private UserProfileDto toUserProfile(User user) {
        return UserProfileDto.builder()
            .id(user.getId())
            .name(user.getName())
            .email(user.getEmail())
            .role(user.getRole())
            .build();
    }
}
