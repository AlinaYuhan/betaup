package com.betaup.dto.checkin;

import lombok.Data;

@Data
public class CheckInRequest {
    private Long gymId;
    private Double userLat;
    private Double userLng;
}
