# Log 01 — Voice Command NLP (DeepSeek Chat API)

**Tool**: DeepSeek Chat API (api.deepseek.com)  
**Component**: `VoiceCommandHandler.java` — backend intent parsing  
**Date**: April 2026

## Prompt

```
You are a voice command parser for a climbing tracking app. Parse the Chinese voice command 
from a climbing user and return a JSON object with a single "intent" field — one of: 
LOG_CLIMB, START_SESSION, or QUERY_STATS — plus any relevant parameters.

The user said: '{userCommand}'

Return only valid JSON, no explanation, no extra fields. Use exactly this schema:
{
  "intent": "LOG_CLIMB",
  "difficulty": "V5",
  "result": "FLASH"
}

Few-shot examples:
Input: "帮我记录一个V4完成" → {"intent":"LOG_CLIMB","difficulty":"V4","result":"SEND"}
Input: "开始今天的训练" → {"intent":"START_SESSION"}
Input: "我今天完成了几条" → {"intent":"QUERY_STATS","period":"today"}
```

## Outcome

**Status**: Success (after 5+ iterations)

Initial responses added hallucinated fields (`confidence`, `raw_text`) outside the schema, causing the Spring Boot handler to fail JSON deserialization in 2 of the first 3 tests.

After adding explicit "no extra fields" and "use exactly this schema" constraints, output became stable.

## Human Modifications

- Added schema validation in `VoiceCommandHandler` to catch any regressions
- Extended intent list to include `QUERY_STATS` with a `period` parameter
- Integrated stable prompt as a constant in the Spring Boot service layer
