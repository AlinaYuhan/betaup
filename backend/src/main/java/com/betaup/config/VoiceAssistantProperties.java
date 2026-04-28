package com.betaup.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "app.voice")
public class VoiceAssistantProperties {

    private String deepseekApiKey;
    private String deepseekEndpoint;
    private String deepseekModel;
}
