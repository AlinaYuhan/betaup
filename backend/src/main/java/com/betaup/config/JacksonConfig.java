package com.betaup.config;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.JsonSerializer;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.module.SimpleModule;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JacksonConfig {

    private static final ZoneId ZONE = ZoneId.of("Asia/Shanghai");

    @Bean
    public SimpleModule localDateTimeModule() {
        SimpleModule module = new SimpleModule("AsiaShanghaiTimeModule");
        module.addSerializer(LocalDateTime.class, new JsonSerializer<LocalDateTime>() {
            @Override
            public void serialize(LocalDateTime value, JsonGenerator gen,
                                  SerializerProvider serializers) throws IOException {
                String formatted = value.atZone(ZONE)
                    .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
                gen.writeString(formatted);
            }
        });
        return module;
    }
}
