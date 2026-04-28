package com.betaup.service;

import com.betaup.dto.voice.VoiceChatRequest;
import com.betaup.dto.voice.VoiceChatResponse;

public interface VoiceAssistantService {

    VoiceChatResponse chat(VoiceChatRequest request);
}
