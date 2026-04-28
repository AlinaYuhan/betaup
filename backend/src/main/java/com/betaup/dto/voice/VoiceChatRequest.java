package com.betaup.dto.voice;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import lombok.Data;

@Data
public class VoiceChatRequest {

    @Valid
    @NotEmpty
    private List<VoiceChatMessageDto> messages;
}
