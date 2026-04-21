package com.betaup.dto.map;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class AmapClientConfigDto {

    private String jsKey;
    private String jsSecurityCode;
}
