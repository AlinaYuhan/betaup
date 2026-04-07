package com.betaup.dto.leaderboard;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class LeaderboardEntry {
    private int rank;
    private Long userId;
    private String name;
    private int score;       // badges count or checkins count depending on board type
}
