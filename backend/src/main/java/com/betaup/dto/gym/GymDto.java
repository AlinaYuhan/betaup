package com.betaup.dto.gym;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GymDto {

    private Long id;
    private String name;
    private String city;
    private String address;
    private double lat;
    private double lng;
    private String phone;
    private String openHours;
    private String types;
    private String bookingUrl;
    private String coverImageUrl;
    private String logoUrl;
}
