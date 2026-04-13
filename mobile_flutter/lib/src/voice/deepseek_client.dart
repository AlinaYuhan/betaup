import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'voice_action.dart';
import 'voice_config.dart';

class DeepSeekClient {
  DeepSeekClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Send [userText] to DeepSeek and return the spoken reply + parsed action.
  /// [history] is the conversation so far (excluding the current user turn).
  Future<({String reply, VoiceAction action})> chat(
    String userText,
    AppSession session, {
    List<ChatMessage> history = const [],
  }) async {
    final activeSession = await _safeFetch(session.api.fetchActiveSession());
    final stats = await _safeFetch(session.api.fetchStats("LAST_7_DAYS"));

    final systemPrompt = _buildSystemPrompt(activeSession, stats);

    // Keep last 8 turns for context (to stay within token limits).
    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    final messages = [
      {"role": "system", "content": systemPrompt},
      for (final msg in recentHistory)
        {"role": msg.isUser ? "user" : "assistant", "content": msg.text},
      {"role": "user", "content": userText},
    ];

    final body = jsonEncode({
      "model": kDeepSeekModel,
      "response_format": {"type": "json_object"},
      "messages": messages,
    });

    final response = await _http.post(
      Uri.parse(kDeepSeekEndpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $kDeepSeekApiKey",
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          "DeepSeek API 错误 ${response.statusCode}: ${response.body}");
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (decoded["choices"] as List).first["message"]["content"] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;

    final reply = parsed["reply"] as String? ?? "好的";
    final actionJson = parsed["action"] as Map<String, dynamic>?;
    return (reply: reply, action: VoiceAction.fromJson(actionJson));
  }

  Future<T?> _safeFetch<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  String _buildSystemPrompt(ClimbSession? session, ClimbStats? stats) {
    final buf = StringBuffer();
    buf.writeln(
      "You are BetaUp Voice, the in-app voice assistant for the BetaUp climbing tracker. "
      "Help users log climbs, manage sessions, query their stats, and answer general climbing questions. "
      "Always reply in the same language the user speaks (Chinese if they speak Chinese). "
      "Be friendly, concise, and encouraging — like a supportive climbing buddy.\n\n"
      "You MUST respond with a JSON object in exactly this format — no extra text:\n"
      '{"reply": "<spoken response>", "action": <action object or null>}\n\n'
      "Supported action types:\n"
      '  LOG_CLIMB:     {"type":"LOG_CLIMB","difficulty":"V5","routeName":null,"result":"FLASH","attempts":1,"notes":null}\n'
      '  START_SESSION: {"type":"START_SESSION","venue":"某岩馆"}\n'
      '  END_SESSION:   {"type":"END_SESSION"}\n'
      '  QUERY_STATS:   {"type":"QUERY_STATS","period":"LAST_7_DAYS"}  // LAST_7_DAYS | LAST_30_DAYS | ALL_TIME\n'
      "  null  — for general conversation, advice, or gym questions\n\n"
      "Result values: FLASH = topped on first try, SEND = topped after attempts, ATTEMPT = did not top.\n"
      "Difficulty: V0-V17 (bouldering) or 5.6-5.15d (sport/top-rope).\n\n"
      "Examples:\n"
      '  User: "刚登了条V5红色，闪送" → {"reply":"太棒了！V5闪送已记录！","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}\n'
      '  User: "开始今天训练" → {"reply":"好的，训练开始！加油！","action":{"type":"START_SESSION","venue":"未知场馆"}}\n'
      '  User: "这周练了多少" → {"reply":"这周你完成了X条路线...","action":{"type":"QUERY_STATS","period":"LAST_7_DAYS"}}\n'
      '  User: "附近有什么岩馆" → {"reply":"我没有实时位置数据，建议在大众点评搜索\'室内攀岩\'，或在高德/百度地图搜索附近攀岩馆。","action":null}\n',
    );

    if (session != null) {
      final startStr = DateFormat("HH:mm").format(session.startTime.toLocal());
      buf.writeln(
          "CURRENT STATE: Active session at '${session.venue}' started at $startStr.");
    } else {
      buf.writeln("CURRENT STATE: No active climbing session.");
    }

    if (stats != null) {
      final s = stats.summary;
      buf.writeln(
        "LAST 7 DAYS: ${s.totalClimbs} climbs — "
        "${s.totalFlashes} flashes, ${s.totalSends} sends, ${s.totalAttempts} attempts. "
        "Flash rate: ${s.flashRatePct}%."
        "${s.topGrade != null ? ' Top grade: ${s.topGrade}.' : ''}",
      );
    }

    return buf.toString();
  }
}
