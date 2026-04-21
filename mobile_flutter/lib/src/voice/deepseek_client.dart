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
    // Fetch all data concurrently to minimise latency.
    final results = await Future.wait([
      _safeFetch(session.api.fetchActiveSession()),
      _safeFetch(session.api.fetchStats("LAST_7_DAYS")),
      _safeFetch(session.api.fetchStats("LAST_30_DAYS")),
      _safeFetch(session.api.fetchStats("ALL_TIME")),
      _safeFetch(session.api.fetchSessions(page: 0, size: 1)),
    ]);
    final activeSession = results[0] as ClimbSession?;
    final stats7   = results[1] as ClimbStats?;
    final stats30  = results[2] as ClimbStats?;
    final statsAll = results[3] as ClimbStats?;
    final recentSessions = results[4] as List<SessionSummary>?;
    final lastVenue = recentSessions?.isNotEmpty == true
        ? (recentSessions!.first.venue.isNotEmpty ? recentSessions.first.venue : null)
        : null;

    final systemPrompt = _buildSystemPrompt(activeSession, stats7, stats30, statsAll, lastVenue);

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

  String _buildSystemPrompt(
    ClimbSession? session,
    ClimbStats? stats7,
    ClimbStats? stats30,
    ClimbStats? statsAll,
    String? lastVenue,
  ) {
    final buf = StringBuffer();
    buf.writeln(
      "你是攀达（Panda），BetaUp 攀岩训练 App 的语音助手，一只热爱攀岩的熊猫。\n"
      "风格：亲切简洁，一句话说完，不啰嗦。用用户相同的语言回复：用户说中文就中文，说英文就英文。\n\n"
      "【你能做的事】\n"
      "- 记录攀爬（LOG_CLIMB）\n"
      "- 开始/结束训练（START_SESSION / END_SESSION）\n"
      "- 查询训练数据（QUERY_STATS）——只用下方【训练统计】里的数字，不编造\n"
      "- 回答攀岩知识、技术、装备问题\n\n"
      "【限制】\n"
      "- 无活跃训练 session 时，拒绝 LOG_CLIMB，引导用户先说【开始训练】\n"
      "- 不编造统计数字\n\n"
      "【语音识别纠正】\n"
      "- STT 容易把 V 级别识别错：'the 5'/'be five'/'V five' 均指 V5，以此类推\n"
      "- 听到 'the N' 或 'be N'（N 为数字）时，自动判断为 VN 级别\n"
      "- 英文 'flash'=FLASH，'send'=SEND，'attempt'/'fell'=ATTEMPT\n\n"
      "【输出格式（严格 JSON，不含多余文字）】\n"
      '{"reply":"<朗读的一句话>","action":<action对象或null>}\n\n'
      "【Action 类型】\n"
      '  LOG_CLIMB:     {"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1,"notes":null}\n'
      '  START_SESSION: {"type":"START_SESSION","venue":"<岩馆名，不确定就用未指定场馆>"}\n'
      '  END_SESSION:   {"type":"END_SESSION"}\n'
      '  QUERY_STATS:   {"type":"QUERY_STATS","period":"LAST_7_DAYS"}\n'
      "  null           — 聊天/知识/无需操作\n\n"
      "result 枚举：FLASH=一次登顶  SEND=多次后登顶  ATTEMPT=未登顶\n"
      "difficulty：V0–V17（抱石）或 5.6–5.15d（运动攀）\n\n"
      "【示例】\n"
      '  "刚闪了条V5" → {"reply":"V5 闪送，记录了！","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}\n'
      '  "I just flashed V5" → {"reply":"V5 flash, logged!","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}\n'
      '  "试了3次才送V4" → {"reply":"V4 三次登顶，加油！","action":{"type":"LOG_CLIMB","difficulty":"V4","result":"SEND","attempts":3}}\n'
      '  "开始训练" → {"reply":"好，训练开始！","action":{"type":"START_SESSION","venue":"<常用场馆或未指定场馆>"}}\n'
      '  无session时说"记录V5" → {"reply":"你还没开始训练哦，先说开始训练吧。","action":null}\n',
    );

    if (session != null) {
      final startStr = DateFormat("HH:mm").format(session.startTime.toLocal());
      buf.writeln("【当前状态】正在训练，场馆：${session.venue}，开始于 $startStr。");
    } else {
      buf.writeln("【当前状态】无活跃训练 session。");
    }

    if (lastVenue != null && lastVenue.isNotEmpty && lastVenue != "未指定场馆") {
      buf.writeln("【常用场馆】$lastVenue（用户上次训练场馆，开始训练时可主动询问是否使用该场馆）");
    }

    buf.writeln("【训练统计】");
    if (stats7 != null) {
      final s = stats7.summary;
      buf.writeln("最近7天：${s.totalClimbs}条 — ${s.totalFlashes}闪 ${s.totalSends}送，"
          "闪送率${s.flashRatePct}%${s.topGrade != null ? '，最高${s.topGrade}' : ''}。");
    }
    if (stats30 != null) {
      final s = stats30.summary;
      buf.writeln("最近30天：${s.totalClimbs}条 — ${s.totalFlashes}闪 ${s.totalSends}送"
          "${s.topGrade != null ? '，最高${s.topGrade}' : ''}。");
    }
    if (statsAll != null) {
      final s = statsAll.summary;
      buf.writeln("历史总计：${s.totalClimbs}条${s.topGrade != null ? '，最高${s.topGrade}' : ''}。");
    }

    return buf.toString();
  }
}
