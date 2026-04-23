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
        "DeepSeek API 错误 ${response.statusCode}: ${response.body}",
      );
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

    buf.writeln('''
你是攀攀（Panda），BetaUp 攀岩训练 App 的语音助手，一只热爱攀岩的熊猫。
风格：亲切简洁，一句话说完，不啰嗦。用用户相同的语言回复：用户说中文就中文，说英文就英文。

【你能做的事】
- 记录攀爬（LOG_CLIMB）
- 开始/结束训练（START_SESSION / END_SESSION）
- 查询训练数据（QUERY_STATS），只能使用下方【训练统计】中的数字，不能编造
- 回答攀岩知识、技术、装备相关问题

【限制】
- 无活跃训练 session 时，拒绝 LOG_CLIMB，引导用户先说“开始训练”
- 不编造统计数据

【语音识别纠错】
- STT 容易把 V 级别识别错：the 5、be five、V five 都可能指 V5，以此类推
- 听到 the N 或 be N（N 为数字）时，优先判断为 VN 级别
- 英文 flash=FLASH，send=SEND，attempt 或 fell=ATTEMPT

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

【示例】
"刚闪了一条 V5" -> {"reply":"V5 Flash，记录好了！","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}
"I just flashed V5" -> {"reply":"V5 flash, logged!","action":{"type":"LOG_CLIMB","difficulty":"V5","result":"FLASH","attempts":1}}
"试了 3 次才送 V4" -> {"reply":"V4 三次完成，已经帮你记下了！","action":{"type":"LOG_CLIMB","difficulty":"V4","result":"SEND","attempts":3}}
"开始训练" -> {"reply":"好，训练开始！","action":{"type":"START_SESSION","venue":"<常用场馆或未指定场馆>"}}
无 session 时说"记录 V5" -> {"reply":"你还没开始训练哦，先说开始训练吧。","action":null}
''');

    if (session != null) {
      final startStr = DateFormat("HH:mm").format(session.startTime.toLocal());
      buf.writeln("【当前状态】正在训练，场馆：${session.venue}，开始于 $startStr。");
    } else {
      buf.writeln("【当前状态】无活跃训练 session。");
    }

    if (lastVenue != null &&
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
