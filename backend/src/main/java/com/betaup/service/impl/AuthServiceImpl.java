package com.betaup.service.impl;

import com.betaup.dto.auth.AuthResponse;
import com.betaup.dto.auth.LoginRequest;
import com.betaup.dto.auth.RegisterRequest;
import com.betaup.dto.auth.UpdateProfileRequest;
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
        String name = request.getName().trim();
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException("该邮箱已被注册。");
        }
        if (userRepository.existsByNameIgnoreCase(name)) {
            throw new ConflictException("该昵称已被使用，请换一个。");
        }

        User userToCreate = User.builder()
            .name(name)
            .email(email)
            .passwordHash(passwordEncoder.encode(request.getPassword()))
            .role(request.getRole() != null ? request.getRole() : com.betaup.entity.UserRole.CLIMBER)
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

    @Override
    @Transactional
    public ApiResponse<UserProfileDto> updateProfile(UpdateProfileRequest request) {
        User user = currentUserService.getCurrentUser();
        if (request.getName() != null && !request.getName().isBlank()) {
            String newName = request.getName().trim();
            if (userRepository.existsByNameIgnoreCaseAndIdNot(newName, user.getId())) {
                throw new ConflictException("该昵称已被使用，请换一个。");
            }
            user.setName(newName);
        }
        if (request.getCity() != null) user.setCity(request.getCity().trim());
        if (request.getBio() != null) user.setBio(request.getBio().trim());
        userRepository.save(user);
        return ApiResponse.success("Profile updated.", toUserProfile(user));
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
            .city(user.getCity())
            .bio(user.getBio())
            .followerCount(user.getFollowerCount())
            .followingCount(user.getFollowingCount())
            .totalClimbLogs(user.getTotalClimbLogs())
            .isCoachCertified(user.isCoachCertified())
            .build();
    }
}
