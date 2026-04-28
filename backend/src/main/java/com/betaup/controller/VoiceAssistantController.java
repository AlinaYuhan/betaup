package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.voice.VoiceChatRequest;
import com.betaup.dto.voice.VoiceChatResponse;
import com.betaup.service.VoiceAssistantService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/voice")
@RequiredArgsConstructor
public class VoiceAssistantController {

    private final VoiceAssistantService voiceAssistantService;

    @PostMapping("/chat")
    public ResponseEntity<ApiResponse<VoiceChatResponse>> chat(@Valid @RequestBody VoiceChatRequest request) {
        return ResponseEntity.ok(
            ApiResponse.success("Voice response generated.", voiceAssistantService.chat(request))
        );
    }
}
