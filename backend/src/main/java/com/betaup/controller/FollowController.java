package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.user.PublicUserDto;
import com.betaup.entity.Follow;
import com.betaup.entity.User;
import com.betaup.repository.FollowRepository;
import com.betaup.repository.UserRepository;
import com.betaup.security.service.CurrentUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class FollowController {

    private final FollowRepository followRepository;
    private final UserRepository userRepository;
    private final CurrentUserService currentUserService;

    @GetMapping("/{targetId}")
    public ResponseEntity<ApiResponse<PublicUserDto>> getUser(@PathVariable Long targetId) {
        User target = userRepository.findById(targetId)
            .orElseThrow(() -> new IllegalArgumentException("User not found."));
        boolean followedByMe = false;
        try {
            User me = currentUserService.getCurrentUser();
            followedByMe = !me.getId().equals(targetId) &&
                followRepository.existsByFollowerIdAndFollowingId(me.getId(), targetId);
        } catch (Exception ignored) {}
        return ResponseEntity.ok(ApiResponse.success("User loaded.", PublicUserDto.builder()
            .id(target.getId())
            .name(target.getName())
            .isCoachCertified(target.isCoachCertified())
            .followerCount(target.getFollowerCount())
            .followingCount(target.getFollowingCount())
            .totalClimbLogs(target.getTotalClimbLogs())
            .followedByMe(followedByMe)
            .build()));
    }

    @PostMapping("/{targetId}/follow")
    public ResponseEntity<ApiResponse<Void>> follow(@PathVariable Long targetId) {
        User me = currentUserService.getCurrentUser();
        if (me.getId().equals(targetId)) {
            throw new IllegalArgumentException("Cannot follow yourself.");
        }
        User target = userRepository.findById(targetId)
            .orElseThrow(() -> new IllegalArgumentException("User not found."));
        if (!followRepository.existsByFollowerIdAndFollowingId(me.getId(), targetId)) {
            followRepository.save(Follow.builder().follower(me).following(target).build());
            me.setFollowingCount(me.getFollowingCount() + 1);
            target.setFollowerCount(target.getFollowerCount() + 1);
            userRepository.save(me);
            userRepository.save(target);
        }
        return ResponseEntity.ok(ApiResponse.success("Followed.", null));
    }

    @DeleteMapping("/{targetId}/follow")
    public ResponseEntity<ApiResponse<Void>> unfollow(@PathVariable Long targetId) {
        User me = currentUserService.getCurrentUser();
        followRepository.findByFollowerIdAndFollowingId(me.getId(), targetId).ifPresent(follow -> {
            followRepository.delete(follow);
            me.setFollowingCount(Math.max(0, me.getFollowingCount() - 1));
            userRepository.findById(targetId).ifPresent(target -> {
                target.setFollowerCount(Math.max(0, target.getFollowerCount() - 1));
                userRepository.save(target);
            });
            userRepository.save(me);
        });
        return ResponseEntity.ok(ApiResponse.success("Unfollowed.", null));
    }

    @GetMapping("/{targetId}/follow-status")
    public ResponseEntity<ApiResponse<Boolean>> followStatus(@PathVariable Long targetId) {
        User me = currentUserService.getCurrentUser();
        boolean following = followRepository.existsByFollowerIdAndFollowingId(me.getId(), targetId);
        return ResponseEntity.ok(ApiResponse.success("Status loaded.", following));
    }
}
