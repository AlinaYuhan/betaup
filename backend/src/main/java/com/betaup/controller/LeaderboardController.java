package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.leaderboard.LeaderboardEntry;
import com.betaup.entity.User;
import com.betaup.repository.CheckInRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.repository.UserRepository;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/leaderboard")
@RequiredArgsConstructor
public class LeaderboardController {

    private static final int TOP_N = 20;

    private final UserRepository userRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final CheckInRepository checkInRepository;

    /**
     * GET /api/leaderboard?type=badges|checkins
     * Returns top 20 climbers ranked by badge count or check-in count.
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<LeaderboardEntry>>> getLeaderboard(
        @RequestParam(defaultValue = "badges") String type
    ) {
        List<User> climbers = userRepository.findAll();

        List<LeaderboardEntry> entries = new ArrayList<>();
        for (User user : climbers) {
            int score = switch (type) {
                case "checkins" -> (int) checkInRepository.countByUserId(user.getId());
                default -> (int) userBadgeRepository.countByUserId(user.getId());
            };
            entries.add(LeaderboardEntry.builder()
                .userId(user.getId())
                .name(user.getName())
                .score(score)
                .rank(0) // filled below
                .build());
        }

        entries.sort(Comparator.comparingInt(LeaderboardEntry::getScore).reversed());

        List<LeaderboardEntry> top = entries.stream()
            .limit(TOP_N)
            .toList();

        // Assign ranks (1-based, ties share same rank)
        int rank = 1;
        for (int i = 0; i < top.size(); i++) {
            if (i > 0 && top.get(i).getScore() < top.get(i - 1).getScore()) {
                rank = i + 1;
            }
            top.get(i).setRank(rank);
        }

        return ResponseEntity.ok(ApiResponse.success("Leaderboard loaded.", top));
    }
}
