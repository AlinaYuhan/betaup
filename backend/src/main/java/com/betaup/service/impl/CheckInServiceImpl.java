package com.betaup.service.impl;

import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.dto.checkin.CheckInRequest;
import com.betaup.dto.checkin.CheckInResult;
import com.betaup.dto.common.ApiResponse;
import com.betaup.entity.CheckIn;
import com.betaup.entity.Gym;
import com.betaup.entity.User;
import com.betaup.repository.CheckInRepository;
import com.betaup.repository.GymRepository;
import com.betaup.repository.UserRepository;
import com.betaup.service.BadgeAutomationService;
import com.betaup.service.CheckInService;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CheckInServiceImpl implements CheckInService {

    private static final double GEOFENCE_RADIUS_METERS = 2000.0;

    private final CheckInRepository checkInRepository;
    private final GymRepository gymRepository;
    private final UserRepository userRepository;
    private final BadgeAutomationService badgeAutomationService;

    @Override
    @Transactional
    public ApiResponse<CheckInResult> checkIn(Long userId, CheckInRequest request) {
        Gym gym = gymRepository.findById(request.getGymId())
            .orElseThrow(() -> new IllegalArgumentException("Gym not found: " + request.getGymId()));
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        LocalDate today = LocalDate.now();
        if (checkInRepository.existsByUserIdAndGymIdAndCheckDate(userId, gym.getId(), today)) {
            return ApiResponse.success("Already checked in at this gym today.",
                buildResult(null, gym, false, List.of()));
        }

        boolean gpsVerified = false;
        if (request.getUserLat() != null && request.getUserLng() != null) {
            double distanceMeters = haversineMeters(
                request.getUserLat(), request.getUserLng(),
                gym.getLat(), gym.getLng()
            );
            if (distanceMeters > GEOFENCE_RADIUS_METERS) {
                throw new IllegalStateException(
                    String.format("You are %.0f m from this gym (limit: %.0f m). Move closer or use Manual Check-In.",
                        distanceMeters, GEOFENCE_RADIUS_METERS));
            }
            gpsVerified = true;
        }

        CheckIn checkIn = CheckIn.builder()
            .user(user)
            .gym(gym)
            .checkDate(today)
            .userLat(request.getUserLat())
            .userLng(request.getUserLng())
            .gpsVerified(gpsVerified)
            .build();
        checkInRepository.save(checkIn);

        List<BadgeProgressDto> newBadges = badgeAutomationService.evaluateUserBadges(user);
        return ApiResponse.success(
            gpsVerified ? "GPS check-in successful!" : "Manual check-in recorded.",
            buildResult(checkIn, gym, gpsVerified, newBadges)
        );
    }

    private CheckInResult buildResult(CheckIn checkIn, Gym gym, boolean gpsVerified,
                                      List<BadgeProgressDto> newBadges) {
        return CheckInResult.builder()
            .checkInId(checkIn != null ? checkIn.getId() : null)
            .gymId(gym.getId())
            .gymName(gym.getName())
            .gpsVerified(gpsVerified)
            .checkedAt(checkIn != null ? checkIn.getCreatedAt() : null)
            .newlyUnlockedBadges(newBadges.isEmpty() ? null : newBadges)
            .build();
    }

    private double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
        final double R = 6_371_000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
