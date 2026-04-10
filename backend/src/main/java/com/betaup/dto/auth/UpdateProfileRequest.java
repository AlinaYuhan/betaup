package com.betaup.dto.auth;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {
    @Size(max = 120)
    private String name;

    @Size(max = 100)
    private String city;

    @Size(max = 300)
    private String bio;
}
