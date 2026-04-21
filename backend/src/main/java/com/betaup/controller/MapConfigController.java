package com.betaup.controller;

import com.betaup.config.AmapProperties;
import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.map.AmapClientConfigDto;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/maps")
@RequiredArgsConstructor
public class MapConfigController {

    private final AmapProperties amapProperties;

    @GetMapping("/amap-config")
    public ResponseEntity<ApiResponse<AmapClientConfigDto>> getAmapConfig() {
        return ResponseEntity.ok(ApiResponse.success(
            "AMap config loaded.",
            AmapClientConfigDto.builder()
                .jsKey(trimToEmpty(amapProperties.getJsKey()))
                .jsSecurityCode(trimToEmpty(amapProperties.getJsSecurityCode()))
                .build()
        ));
    }

    private String trimToEmpty(String value) {
        return value == null ? "" : value.trim();
    }
}
