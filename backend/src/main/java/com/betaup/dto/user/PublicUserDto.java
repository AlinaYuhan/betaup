package com.betaup.dto.user;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PublicUserDto {
    private Long id;
    private String name;
    private boolean isCoachCertified;
    private int followerCount;
    private int followingCount;
    private int totalClimbLogs;
    private boolean followedByMe;
}
