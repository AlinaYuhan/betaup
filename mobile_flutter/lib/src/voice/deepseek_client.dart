import 'dart:convert';

import 'package:flutter/foundation.dart';
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
    final results = await Future.wait([
      _safeFetch(session.api.fetchActiveSession()),
      _safeFetch(session.api.fetchStats("LAST_7_DAYS")),
      _safeFetch(session.api.fetchStats("LAST_30_DAYS")),
      _safeFetch(session.api.fetchStats("ALL_TIME")),
      _safeFetch(session.api.fetchSessions(page: 0, size: 1)),
    ]);

    final activeSession = results[0] as ClimbSession?;
    final stats7 = results[1] as ClimbStats?;
    final stats30 = results[2] as ClimbStats?;
    final statsAll = results[3] as ClimbStats?;
    final recentSessions = results[4] as List<SessionSummary>?;
    final lastVenue = recentSessions?.isNotEmpty == true
        ? (recentSessions!.first.venue.isNotEmpty
              ? recentSessions.first.venue
              : null)
        : null;

    final systemPrompt = _buildSystemPrompt(
      activeSession,
      stats7,
      stats30,
      statsAll,
      lastVenue,
      session.nearbyGymName,
    );

    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    final messages = [
      {"role": "system", "content": systemPrompt},
      for (final message in recentHistory)
        {
          "role": message.isUser ? "user" : "assistant",
          "content": message.text,
        },
      {"role": "user", "content": userText},
    ];

    final body = jsonEncode({
      "model": kDeepSeekModel,
      "response_format": {"type": "json_object"},
      "messages": messages,
    });

    // Try up to 2 times — DeepSeek occasionally returns blank content with
    // response_format:json_object even on a successful 200.
    for (int attempt = 1; attempt <= 2; attempt++) {
      final response = await _http.post(
        Uri.parse(kDeepSeekEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $kDeepSeekApiKey",
        },
        body: body,
      );

      debugPrint('[DeepSeek] attempt=$attempt status=${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          "DeepSeek API 错误 ${response.statusCode}: ${response.body}",
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final raw =
          (decoded["choices"] as List).first["message"]["content"] as String;
      final content = _stripCodeFences(raw);

      debugPrint('[DeepSeek] content=${content.length > 200 ? content.substring(0, 200) : content}');

      // Blank response — retry once before giving up.
      if (content.trim().isEmpty) {
        debugPrint('[DeepSeek] blank content, ${attempt < 2 ? "retrying..." : "giving up"}');
        if (attempt < 2) continue;
        break;
      }

      Map<String, dynamic>? parsed;
      try {
        parsed = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        // Plain text response — use as-is (no action).
        debugPrint('[DeepSeek] non-JSON, using raw');
        return (reply: content.trim(), action: VoiceAction.fromJson(null));
      }

      final rawReply = (parsed["reply"] as String?)?.trim() ?? '';
      debugPrint('[DeepSeek] reply="$rawReply"');
      final reply = rawReply.isNotEmpty ? rawReply : content.trim();
      final actionJson = parsed["action"] as Map<String, dynamic>?;
      return (reply: reply, action: VoiceAction.fromJson(actionJson));
    }

    // Both attempts returned blank — return empty so caller uses fallback.
    return (reply: '', action: VoiceAction.fromJson(null));
  }

  /// Remove ```json ... ``` or ``` ... ``` wrappers that DeepSeek sometimes adds.
  static String _stripCodeFences(String s) {
    final trimmed = s.trim();
    // Match ```json\n...\n``` or ```\n...\n```
    final fenceRegex = RegExp(r'^```(?:json)?\s*\n?([\s\S]*?)\n?```$');
    final match = fenceRegex.firstMatch(trimmed);
    if (match != null) return match.group(1)!.trim();
    return trimmed;
  }

  Future<T?> _safeFetch<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  String _buildSystemPrompt(
    ClimbSession? session,
    ClimbStats? stats7,
    ClimbStats? stats30,
    ClimbStats? statsAll,
    String? lastVenue,
    String? nearbyGym,
  ) {
    final buf = StringBuffer();

    buf.writeln('''
你是攀攀（Panda），BetaUp 攀岩训练 App 的语音助手，一只热爱攀岩的熊猫。
风格：亲切简洁，一句话说完，不啰嗦。

【语言规则 — 必须严格执行】
- 用户用英文说话 → reply 字段只能用英文，不能夹杂中文
- 用户用中文说话 → reply 字段只能用中文，不能夹杂英文
- 每条消息独立判断，不受上下文语言影响
- 错误示例：用户说英文，你回中文 ✗；用户说中文，你回英文 ✗

【你能做的事】
- 记录攀爬（LOG_CLIMB）
- 开始/结束训练（START_SESSION / END_SESSION）
- 查询训练数据（QUERY_STATS），只能使用下方【训练统计】中的数字，不能编造
- 回答攀岩知识、技术、装备相关问题

【限制】
- 无活跃训练 session 时，拒绝 LOG_CLIMB，引导用户先说“开始训练”
- 不编造统计数据

【语音识别纠错】
STT 英文识别常见错误，遇到时自动纠正再理解：
- V级别："be 5" / "the 5" / "v five" / "fee five" / "we 5" / "b5" → V5，依此类推
- "require" / "record" / "recall" / "required" → record a climb
- "flash" / "flesh" / "flask" → FLASH
- "send" / "sand" / "sent" → SEND
- "attempt" / "a temp" / "a tent" / "fell" / "fail" → ATTEMPT
- "start" / "stock" / "start a" → start session
- "end" / "and session" / "in session" → end session
- 数字后面跟 attempt/attempts/tries → attempts 次数
- 只说 "yes" / "yeah" / "correct" → 回应上一个问题（如确认结果类型）

【输出格式】
严格输出 JSON，不要附带额外说明：
{"reply":"<朗读的一句话>","action":<action对象或null>}

【Action 类型】
LOG_CLIMB: {"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1,"notes":null}
START_SESSION: {"type":"START_SESSION","venue":"<场馆名，不确定就用未指定场馆>"}
END_SESSION: {"type":"END_SESSION"}
QUERY_STATS: {"type":"QUERY_STATS","period":"LAST_7_DAYS"}
null: 纯聊天、知识问答或无需操作

result 枚举：
- FLASH = 一次登顶
- SEND = 多次尝试后登顶
- ATTEMPT = 尚未登顶

difficulty：
- 抱石使用 V0-V17
- 运动攀使用 5.6-5.15d

【示例】（注意语言严格匹配）
"刚闪了一条 V5" -> {"reply":"V5 Flash，记录好了！","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}
"I just flashed V5" -> {"reply":"V5 flash, logged!","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}
"can you recommend a nearby gym" -> {"reply":"The nearest gym is <gym name>. Easy to get there!","action":null}
"试了 3 次才送 V4" -> {"reply":"V4 三次完成，已经帮你记下了！","action":{"type":"LOG_CLIMB","difficulty":"V4","result":"SEND","attempts":3}}
"开始训练" -> {"reply":"好，训练开始！","action":{"type":"START_SESSION","venue":"<常用场馆或未指定场馆>"}}
"start a session" -> {"reply":"Session started!","action":{"type":"START_SESSION","venue":"<venue name>"}}
无 session 时说"记录 V5" -> {"reply":"你还没开始训练哦，先说开始训练吧。","action":null}
no session and user says "log V5" -> {"reply":"Start a session first, then I can log your climb!","action":null}
''');

    if (session != null) {
      final startStr = DateFormat("HH:mm").format(session.startTime.toLocal());
      buf.writeln("【当前状态】正在训练，场馆：${session.venue}，开始于 $startStr。");
    } else {
      buf.writeln("【当前状态】无活跃训练 session。");
    }

    if (nearbyGym != null && nearbyGym.isNotEmpty) {
      buf.writeln('【GPS最近场馆】$nearbyGym（用户当前位置最近的攀岩馆，用户说开始训练时优先使用此场馆名。）');
    } else if (lastVenue != null &&
        lastVenue.isNotEmpty &&
        lastVenue != "未指定场馆") {
      buf.writeln("【常用场馆】$lastVenue（用户上次训练的场馆，可在开始训练时优先参考。）");
    }

    buf.writeln("【训练统计】");
    if (stats7 != null) {
      final summary = stats7.summary;
      buf.writeln(
        "最近7天：${summary.totalClimbs}条，Flash ${summary.totalFlashes} 次，Send ${summary.totalSends} 次，"
        "Flash 率 ${summary.flashRatePct}%${summary.topGrade != null ? "，最高 ${summary.topGrade}" : ""}。",
      );
    }
    if (stats30 != null) {
      final summary = stats30.summary;
      buf.writeln(
        "最近30天：${summary.totalClimbs}条，Flash ${summary.totalFlashes} 次，Send ${summary.totalSends} 次"
        "${summary.topGrade != null ? "，最高 ${summary.topGrade}" : ""}。",
      );
    }
    if (statsAll != null) {
      final summary = statsAll.summary;
      buf.writeln(
        "历史总计：${summary.totalClimbs}条${summary.topGrade != null ? "，最高 ${summary.topGrade}" : ""}。",
      );
    }

    return buf.toString();
  }
}
