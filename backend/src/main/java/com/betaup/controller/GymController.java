package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.gym.GymDto;
import com.betaup.entity.Gym;
import com.betaup.repository.GymRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/gyms")
@RequiredArgsConstructor
public class GymController {

    private final GymRepository gymRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<GymDto>>> getGyms(
        @RequestParam(required = false) String city
    ) {
        List<Gym> gyms = (city != null && !city.isBlank())
            ? gymRepository.findByCity(city)
            : gymRepository.findAll();
        List<GymDto> dtos = gyms.stream().map(this::toDto).toList();
        return ResponseEntity.ok(ApiResponse.success("Gyms loaded.", dtos));
    }

    private GymDto toDto(Gym gym) {
        return GymDto.builder()
            .id(gym.getId())
            .name(gym.getName())
            .city(gym.getCity())
            .address(gym.getAddress())
            .lat(gym.getLat())
            .lng(gym.getLng())
            .phone(gym.getPhone())
            .openHours(gym.getOpenHours())
            .types(gym.getTypes())
            .bookingUrl(gym.getBookingUrl())
            .coverImageUrl(gym.getCoverImageUrl())
            .logoUrl(gym.getLogoUrl())
            .build();
    }
}
