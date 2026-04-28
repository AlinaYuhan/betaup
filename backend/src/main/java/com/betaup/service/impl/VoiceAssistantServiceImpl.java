package com.betaup.service.impl;

import com.betaup.config.VoiceAssistantProperties;
import com.betaup.dto.voice.VoiceChatMessageDto;
import com.betaup.dto.voice.VoiceChatRequest;
import com.betaup.dto.voice.VoiceChatResponse;
import com.betaup.service.VoiceAssistantService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class VoiceAssistantServiceImpl implements VoiceAssistantService {

    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(30);

    private final VoiceAssistantProperties properties;
    private final ObjectMapper objectMapper;
    private final HttpClient httpClient = HttpClient.newHttpClient();

    @Override
    public VoiceChatResponse chat(VoiceChatRequest request) {
        String apiKey = trimToNull(properties.getDeepseekApiKey());
        if (apiKey == null) {
            throw new IllegalStateException("Voice assistant is not configured on the server.");
        }

        String endpoint = trimToNull(properties.getDeepseekEndpoint());
        String model = trimToNull(properties.getDeepseekModel());
        if (endpoint == null || model == null) {
            throw new IllegalStateException("Voice assistant endpoint or model is missing.");
        }

        String requestBody = writeRequestBody(request.getMessages(), model);

        for (int attempt = 1; attempt <= 2; attempt++) {
            String upstreamBody = callDeepSeek(endpoint, apiKey, requestBody);
            VoiceChatResponse parsed = parseUpstreamResponse(upstreamBody);
            if (parsed.getReply() != null && !parsed.getReply().isBlank()) {
                return parsed;
            }
        }

        return new VoiceChatResponse("", null);
    }

    private String writeRequestBody(List<VoiceChatMessageDto> messages, String model) {
        List<Map<String, String>> serializedMessages = messages.stream()
            .map(message -> Map.of(
                "role", message.getRole().trim(),
                "content", message.getContent().trim()
            ))
            .toList();

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("model", model);
        payload.put("response_format", Map.of("type", "json_object"));
        payload.put("messages", serializedMessages);

        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Failed to serialize voice request.", ex);
        }
    }

    private String callDeepSeek(String endpoint, String apiKey, String requestBody) {
        HttpRequest request = HttpRequest.newBuilder(URI.create(endpoint))
            .timeout(REQUEST_TIMEOUT)
            .header("Content-Type", "application/json")
            .header("Authorization", "Bearer " + apiKey)
            .POST(HttpRequest.BodyPublishers.ofString(requestBody))
            .build();

        HttpResponse<String> response;
        try {
            response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
        } catch (IOException | InterruptedException ex) {
            if (ex instanceof InterruptedException) {
                Thread.currentThread().interrupt();
            }
            throw new IllegalStateException("Voice assistant upstream request failed.", ex);
        }

        if (response.statusCode() != 200) {
            throw new IllegalStateException("Voice assistant upstream error " + response.statusCode() + ": " + response.body());
        }

        return response.body();
    }

    private VoiceChatResponse parseUpstreamResponse(String responseBody) {
        JsonNode root;
        try {
            root = objectMapper.readTree(responseBody);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Voice assistant returned invalid JSON.", ex);
        }

        String rawContent = root.path("choices").path(0).path("message").path("content").asText("");
        String content = stripCodeFences(rawContent);
        if (content.isBlank()) {
            return new VoiceChatResponse("", null);
        }

        try {
            JsonNode parsed = objectMapper.readTree(content);
            String reply = parsed.path("reply").asText("").trim();
            if (reply.isEmpty()) {
                reply = content.trim();
            }
            JsonNode action = parsed.get("action");
            return new VoiceChatResponse(reply, action != null && !action.isNull() ? action : null);
        } catch (JsonProcessingException ex) {
            return new VoiceChatResponse(content.trim(), null);
        }
    }

    private String stripCodeFences(String value) {
        String trimmed = value == null ? "" : value.trim();
        if (trimmed.startsWith("```") && trimmed.endsWith("```")) {
            String inner = trimmed.substring(3, trimmed.length() - 3).trim();
            if (inner.startsWith("json")) {
                inner = inner.substring(4).trim();
            }
            return inner;
        }
        return trimmed;
    }

    private String trimToNull(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
