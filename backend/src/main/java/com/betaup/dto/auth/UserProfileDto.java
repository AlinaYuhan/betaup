package com.betaup.dto.auth;

import com.betaup.entity.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileDto {

    private Long id;
    private String name;
    private String email;
    private UserRole role;
    private String city;
    private String bio;
    private int followerCount;
    private int followingCount;
    private int totalClimbLogs;
    private boolean isCoachCertified;
}
