import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'voice_action.dart';

class DeepSeekClient {
  DeepSeekClient();

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
      session: activeSession,
      stats7: stats7,
      stats30: stats30,
      statsAll: statsAll,
      lastVenue: lastVenue,
      nearbyGym: session.nearbyGymName,
    );

    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;

    final messages = <JsonMap>[
      {"role": "system", "content": systemPrompt},
      for (final message in recentHistory)
        {
          "role": message.isUser ? "user" : "assistant",
          "content": message.text,
        },
      {"role": "user", "content": userText},
    ];

    debugPrint(
      '[VoiceProxy] payloadBytes=${utf8.encode(jsonEncode(messages)).length}',
    );

    final result = await session.api.voiceChat(messages: messages);
    debugPrint('[VoiceProxy] reply="${result.reply}"');

    return (
      reply: result.reply,
      action: VoiceAction.fromJson(result.action),
    );
  }

  Future<T?> _safeFetch<T>(Future<T> future) async {
    try {
      return await future;
    } catch (_) {
      return null;
    }
  }

  String _buildSystemPrompt({
    required ClimbSession? session,
    required ClimbStats? stats7,
    required ClimbStats? stats30,
    required ClimbStats? statsAll,
    required String? lastVenue,
    required String? nearbyGym,
  }) {
    final buf = StringBuffer();

    buf.writeln('''
你是 Panda，BetaUp 攀岩训练 App 的语音助手。

风格要求：
- 亲切、简洁、直接
- 一次回复尽量一句话
- 不要输出多余解释

语言规则：
- 用户说英文时，reply 只能用英文
- 用户说中文时，reply 只能用中文
- 每条消息独立判断语言，不要被上一轮影响

你可以做的事：
- 记录攀爬（LOG_CLIMB）
- 开始训练（START_SESSION）
- 结束训练（END_SESSION）
- 回答统计问题（QUERY_STATS）
- 回答一般攀岩知识问题

限制：
- 没有 active session 时，不要触发 LOG_CLIMB
- 不要编造统计数据

语音纠错提示：
- "be 5" / "the 5" / "v five" / "fee five" / "we 5" / "b5" 通常表示 V5
- "flash" / "flesh" / "flask" 通常表示 FLASH
- "send" / "sand" / "sent" 通常表示 SEND
- "attempt" / "a temp" / "a tent" / "fell" / "fail" 通常表示 ATTEMPT
- "start" / "stock" / "start a" 通常表示 start session
- "end" / "and session" / "in session" 通常表示 end session

输出格式：
严格输出 JSON，不要额外说明：
{"reply":"...","action":{...}}

action 类型：
- LOG_CLIMB
- START_SESSION
- END_SESSION
- QUERY_STATS
- 或 null

示例：
- "I just flashed V5" -> {"reply":"V5 flash, logged!","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}
- "刚刚闪了一条 V5" -> {"reply":"V5 Flash，已经帮你记下了。","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}
- "start a session" -> {"reply":"Session started!","action":{"type":"START_SESSION","venue":"<venue name>"}}
- 没有 session 时说“记录 V5” -> {"reply":"你还没有开始训练，先说开始训练吧。","action":null}
''');

    if (session != null) {
      final startStr = DateFormat("HH:mm").format(session.startTime.toLocal());
      buf.writeln('当前状态：正在训练，场馆 ${session.venue}，开始于 $startStr。');
    } else {
      buf.writeln('当前状态：没有 active session。');
    }

    if (nearbyGym != null && nearbyGym.isNotEmpty) {
      buf.writeln('最近场馆：$nearbyGym。用户开始训练时优先参考这个场馆。');
    } else if (lastVenue != null &&
        lastVenue.isNotEmpty &&
        lastVenue != '未指定场馆') {
      buf.writeln('最近一次训练场馆：$lastVenue。');
    }

    buf.writeln('训练统计：');
    if (stats7 != null) {
      final summary = stats7.summary;
      buf.writeln(
        '最近 7 天：${summary.totalClimbs} 条，'
        'Flash ${summary.totalFlashes} 次，'
        'Send ${summary.totalSends} 次，'
        'Flash rate ${summary.flashRatePct}%'
        '${summary.topGrade != null ? '，最高 ${summary.topGrade}' : ''}。',
      );
    }
    if (stats30 != null) {
      final summary = stats30.summary;
      buf.writeln(
        '最近 30 天：${summary.totalClimbs} 条，'
        'Flash ${summary.totalFlashes} 次，'
        'Send ${summary.totalSends} 次'
        '${summary.topGrade != null ? '，最高 ${summary.topGrade}' : ''}。',
      );
    }
    if (statsAll != null) {
      final summary = statsAll.summary;
      buf.writeln(
        '历史总计：${summary.totalClimbs} 条'
        '${summary.topGrade != null ? '，最高 ${summary.topGrade}' : ''}。',
      );
    }

    return buf.toString();
  }
}
