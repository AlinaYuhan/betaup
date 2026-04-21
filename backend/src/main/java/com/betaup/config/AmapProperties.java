package com.betaup.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "app.amap")
public class AmapProperties {

    private String jsKey;
    private String jsSecurityCode;
    private String webServiceKey;
    private String geocodeUrl;
}
