import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'deepseek_client.dart';
import 'voice_action.dart';
import 'voice_speech.dart';

enum VoiceState { idle, listening, processing, responding, error }

class VoiceService extends ChangeNotifier {
  VoiceService(this._session) : _deepseek = DeepSeekClient();

  final AppSession _session;
  final DeepSeekClient _deepseek;
  final SpeechToText _stt = SpeechToText();

  VoiceState _state = VoiceState.idle;
  String? _errorMessage;
  bool _sttReady = false;
  String _sttLocale = 'zh-CN'; // toggleable by user
  bool _processingTriggered = false;
  bool _conversationOpen = false;
  final List<ChatMessage> _messages = [];
  List<BadgeProgress>? _pendingBadges;
  String? _interimText;

  VoiceState get state => _state;
  String? get errorMessage => _errorMessage;
  String get sttLocale => _sttLocale;

  void toggleSttLocale() {
    _sttLocale = _sttLocale == 'zh-CN' ? 'en-US' : 'zh-CN';
    _sttReady = false; // force re-init with new locale
    notifyListeners();
  }
  bool get conversationOpen => _conversationOpen;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<BadgeProgress> get pendingBadges => _pendingBadges ?? const [];

  void clearPendingBadges() {
    _pendingBadges = null;
  }

  /// Real-time transcript shown while listening; null at other times.
  String? get interimText => _state == VoiceState.listening ? _interimText : null;

  /// Open the chat panel and start the first listening turn.
  Future<void> openConversation() async {
    if (_conversationOpen) {
      if (_state == VoiceState.idle) {
        await startListening();
      }
      return;
    }

    _conversationOpen = true;
    notifyListeners();

    if (_messages.isEmpty) {
      const greeting =
          "嗨，我是攀攀。你可以说“开始训练”“记录攀爬”“查看统计”，或者直接问我攀岩相关问题。";
      _messages.add(const ChatMessage(text: greeting, isUser: false));
      notifyListeners();
      _setState(VoiceState.responding);
      await speakText(greeting);
      _setState(VoiceState.idle);
    }

    await startListening();
  }

  /// Close the chat panel and stop everything.
  void closeConversation() {
    _conversationOpen = false;
    _stt.stop();
    stopSpeaking();
    _messages.clear();
    _interimText = null;
    _errorMessage = null;
    _setState(VoiceState.idle);
  }

  Future<void> startListening() async {
    if (_state != VoiceState.idle) {
      return;
    }

    if (!kIsWeb) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _setError("需要麦克风权限才能使用语音助手。");
        return;
      }
    }

    if (!_sttReady) {
      _sttReady = await _stt.initialize(
        onError: (_) {
          if (_state == VoiceState.listening) {
            _handleListeningDone();
          }
        },
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            _handleListeningDone();
          }
        },
      );
    }

    if (!_sttReady) {
      _setError("语音识别初始化失败，请检查设备是否支持。");
      return;
    }

    try {
      await _stt.stop();
    } catch (_) {}
    // Brief pause so any stale onStatus("done") callbacks fire while we're
    // still in idle state and get ignored by _handleListeningDone's guard.
    await Future.delayed(const Duration(milliseconds: 150));

    _interimText = null;
    _processingTriggered = false;
    _setState(VoiceState.listening);

    await _stt.listen(
      onResult: (result) {
        _interimText = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) {
          _handleListeningDone();
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      localeId: _sttLocale,
    );
  }

  /// Manually stop recording and process whatever was captured.
  Future<void> stopListening() async {
    if (_state != VoiceState.listening) {
      return;
    }
    await _stt.stop();
  }

  /// Interrupt TTS mid-playback and immediately start listening again.
  void interruptSpeaking() {
    if (_state != VoiceState.responding) {
      return;
    }
    stopSpeaking();
    _setState(VoiceState.idle);
    if (_conversationOpen) {
      Future.delayed(const Duration(milliseconds: 200), startListening);
    }
  }

  /// Reset from error state and optionally re-open listening.
  void reset() {
    _stt.stop();
    _errorMessage = null;
    _setState(VoiceState.idle);
    if (_conversationOpen) {
      Future.delayed(const Duration(milliseconds: 400), startListening);
    }
  }

  void _handleListeningDone() {
    if (_processingTriggered || _state != VoiceState.listening) {
      return;
    }
    _processingTriggered = true;

    final text = (_interimText ?? "").trim();
    _interimText = null;

    if (text.isNotEmpty) {
      _processTranscript(text);
      return;
    }

    _setState(VoiceState.idle);
    if (_conversationOpen) {
      Future.delayed(const Duration(milliseconds: 600), startListening);
    }
  }

  Future<void> _processTranscript(String text) async {
    _setState(VoiceState.processing);

    _messages.add(ChatMessage(text: text, isUser: true));
    notifyListeners();

    String replyText;
    VoiceAction action = const NoAction();
    bool isFallback = false;

    try {
      // Only send real (non-fallback) messages as history to avoid teaching
      // the AI to mimic short/empty responses it generated during failures.
      final realHistory = _messages
          .where((m) => !m.isFallback)
          .toList();
      final historyForLlm = realHistory.length > 1
          ? realHistory.sublist(0, realHistory.length - 1)
          : const <ChatMessage>[];

      final result =
          await _deepseek.chat(text, _session, history: historyForLlm);

      replyText = result.reply.trim();
      if (replyText.isEmpty) {
        replyText = _sttLocale == 'zh-CN'
            ? "好的，我明白了！"
            : "Got it!";
        isFallback = true;
      }
      action = result.action;
    } catch (_) {
      replyText = _sttLocale == 'zh-CN'
          ? "抱歉，我没有响应，你可以重新说一遍吗？"
          : "Sorry, something went wrong. Could you say that again?";
      isFallback = true;
    }

    // Always show the reply bubble before going back to listening.
    _messages.add(ChatMessage(text: replyText, isUser: false, isFallback: isFallback));
    notifyListeners();

    _setState(VoiceState.responding);
    await speakText(replyText);
    await _executeAction(action);
    _setState(VoiceState.idle);

    if (_conversationOpen) {
      await Future.delayed(const Duration(milliseconds: 300));
      await startListening();
    }
  }

  Future<void> _executeAction(VoiceAction action) async {
    try {
      switch (action) {
        case LogClimbAction(
            :final difficulty,
            :final routeName,
            :final result,
            :final attempts,
            :final notes,
          ):
          final activeSession =
              await _session.api.fetchActiveSession().catchError((_) => null);
          if (activeSession == null) {
            return;
          }

          final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
          final log = await _session.api.createClimb({
            "difficulty": difficulty,
            if (routeName != null && routeName.isNotEmpty)
              "routeName": routeName,
            "date": today,
            "venue": activeSession.venue,
            "result": result,
            "attempts": attempts,
            if (notes != null && notes.isNotEmpty) "notes": notes,
            "sessionId": activeSession.id,
          });
          if (log.newlyUnlockedBadges.isNotEmpty) {
            (_pendingBadges ??= []).addAll(log.newlyUnlockedBadges);
            notifyListeners();
          }
          _session.bumpVoiceVersion();

        case StartSessionAction(:final venue):
          await _session.api.startSession(venue);
          _session.bumpVoiceVersion();

        case EndSessionAction():
          final active =
              await _session.api.fetchActiveSession().catchError((_) => null);
          if (active != null) {
            await _session.api.endSession(active.id);
          }
          _session.bumpVoiceVersion();

        case QueryStatsAction():
          break;

        case NoAction():
          break;
      }
    } catch (_) {
      const errMsg = "抱歉，操作没有成功，你可以再试一次。";
      _messages.add(const ChatMessage(text: errMsg, isUser: false));
      notifyListeners();
      await speakText(errMsg);
    }
  }

  void _setState(VoiceState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(VoiceState.error);
  }

  @override
  void dispose() {
    _stt.stop();
    stopSpeaking();
    super.dispose();
  }
}
