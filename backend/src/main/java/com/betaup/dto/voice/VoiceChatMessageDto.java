package com.betaup.dto.voice;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class VoiceChatMessageDto {

    @NotBlank
    @Pattern(regexp = "system|user|assistant", message = "role must be system, user, or assistant")
    private String role;

    @NotBlank
    private String content;
}
