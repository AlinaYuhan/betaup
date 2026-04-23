/// Sealed hierarchy representing actions the LLM may instruct the app to take.
sealed class VoiceAction {
  const VoiceAction();

  factory VoiceAction.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NoAction();
    final type = json["type"] as String? ?? "";
    return switch (type) {
      "LOG_CLIMB" => LogClimbAction.fromJson(json),
      "START_SESSION" => StartSessionAction.fromJson(json),
      "END_SESSION" => const EndSessionAction(),
      "QUERY_STATS" => QueryStatsAction.fromJson(json),
      _ => const NoAction(),
    };
  }
}

/// Log a climb to the current session (or without a session).
class LogClimbAction extends VoiceAction {
  const LogClimbAction({
    required this.difficulty,
    this.routeName,
    required this.result,
    this.attempts = 1,
    this.notes,
  });

  /// Grade string, e.g. "V5" or "5.11a"
  final String difficulty;
  final String? routeName;

  /// "FLASH" | "SEND" | "ATTEMPT"
  final String result;
  final int attempts;
  final String? notes;

  factory LogClimbAction.fromJson(Map<String, dynamic> json) => LogClimbAction(
        difficulty: (json["difficulty"] as String? ?? "").toUpperCase(),
        routeName: json["routeName"] as String?,
        result: (json["result"] as String? ?? "SEND").toUpperCase(),
        attempts: (json["attempts"] as num?)?.toInt() ?? 1,
        notes: json["notes"] as String?,
      );
}

/// Start a new climbing session at a given venue.
class StartSessionAction extends VoiceAction {
  const StartSessionAction({this.venue = "未指定场馆"});

  final String venue;

  factory StartSessionAction.fromJson(Map<String, dynamic> json) =>
      StartSessionAction(venue: json["venue"] as String? ?? "未指定场馆");
}

/// End the currently active session.
class EndSessionAction extends VoiceAction {
  const EndSessionAction();
}

/// Query climbing statistics; the reply text already contains the answer.
class QueryStatsAction extends VoiceAction {
  const QueryStatsAction({this.period = "LAST_7_DAYS"});

  /// "LAST_7_DAYS" | "LAST_30_DAYS" | "ALL_TIME"
  final String period;

  factory QueryStatsAction.fromJson(Map<String, dynamic> json) =>
      QueryStatsAction(period: json["period"] as String? ?? "LAST_7_DAYS");
}

/// The LLM responded conversationally without triggering an app action.
class NoAction extends VoiceAction {
  const NoAction();
}

/// One turn in the voice conversation.
class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}
