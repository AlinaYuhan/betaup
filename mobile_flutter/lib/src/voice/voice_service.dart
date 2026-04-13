import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../session/app_session.dart';
import 'deepseek_client.dart';
import 'voice_action.dart';

enum VoiceState { idle, listening, processing, responding, error }

class VoiceService extends ChangeNotifier {
  VoiceService(this._session) : _deepseek = DeepSeekClient();

  final AppSession _session;
  final DeepSeekClient _deepseek;
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceState _state = VoiceState.idle;
  String? _errorMessage;
  bool _sttReady = false;
  bool _processingTriggered = false;
  bool _conversationOpen = false;

  // Conversation history (all turns, for display and LLM context).
  final List<ChatMessage> _messages = [];

  // The text being recognised in real-time (shown as interim bubble).
  String? _interimText;

  // Getters ───────────────────────────────────────────────────────────────────
  VoiceState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get conversationOpen => _conversationOpen;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Real-time transcript shown while listening; null at other times.
  String? get interimText => _state == VoiceState.listening ? _interimText : null;

  // ── Public interface ────────────────────────────────────────────────────────

  /// Open the chat panel and start the first listening turn.
  Future<void> openConversation() async {
    if (_conversationOpen) {
      // Already open — just (re)start listening if idle.
      if (_state == VoiceState.idle) await startListening();
      return;
    }
    _conversationOpen = true;
    notifyListeners();
    await startListening();
  }

  /// Close the chat panel and stop everything.
  void closeConversation() {
    _conversationOpen = false;
    _stt.stop();
    _tts.stop();
    _messages.clear();
    _interimText = null;
    _errorMessage = null;
    _setState(VoiceState.idle);
  }

  Future<void> startListening() async {
    if (_state != VoiceState.idle) return;

    // Web handles mic permission natively; skip permission_handler on web.
    if (!kIsWeb) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _setError("需要麦克风权限才能使用语音助手");
        return;
      }
    }

    if (!_sttReady) {
      _sttReady = await _stt.initialize(
        onError: (_) {
          if (_state == VoiceState.listening) _handleListeningDone();
        },
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            _handleListeningDone();
          }
        },
      );
    }

    if (!_sttReady) {
      _setError("语音识别初始化失败，请检查设备是否支持");
      return;
    }

    _interimText = null;
    _processingTriggered = false;
    _setState(VoiceState.listening);

    await _stt.listen(
      onResult: (result) {
        _interimText = result.recognizedWords;
        notifyListeners();
        if (result.finalResult) _handleListeningDone();
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
    );
  }

  /// Manually stop recording and process whatever was captured.
  Future<void> stopListening() async {
    if (_state != VoiceState.listening) return;
    await _stt.stop();
    // onStatus("notListening") will fire → _handleListeningDone
  }

  /// Reset from error state and optionally re-open listening.
  void reset() {
    _stt.stop();
    _tts.stop();
    _errorMessage = null;
    _setState(VoiceState.idle);
    if (_conversationOpen) {
      Future.delayed(const Duration(milliseconds: 400), startListening);
    }
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _handleListeningDone() {
    if (_processingTriggered || _state != VoiceState.listening) return;
    _processingTriggered = true;

    final text = (_interimText ?? "").trim();
    _interimText = null;

    if (text.isNotEmpty) {
      _processTranscript(text);
    } else {
      _setState(VoiceState.idle);
      // Nothing heard — wait briefly then try again if conversation is open.
      if (_conversationOpen) {
        Future.delayed(const Duration(milliseconds: 600), startListening);
      }
    }
  }

  Future<void> _processTranscript(String text) async {
    _setState(VoiceState.processing);

    // Show the user's message immediately in the chat panel.
    _messages.add(ChatMessage(text: text, isUser: true));
    notifyListeners();

    try {
      // Pass history without the current turn (it's passed as userText).
      final historyForLLM = _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : const <ChatMessage>[];

      final result =
          await _deepseek.chat(text, _session, history: historyForLLM);

      _messages.add(ChatMessage(text: result.reply, isUser: false));
      notifyListeners();

      _setState(VoiceState.responding);
      await _tts.setLanguage("zh-CN");

      // Use a Completer so we can await TTS completion reliably.
      final ttsCompleter = Completer<void>();
      _tts.setCompletionHandler(() {
        if (!ttsCompleter.isCompleted) ttsCompleter.complete();
      });
      _tts.setErrorHandler((_) {
        if (!ttsCompleter.isCompleted) ttsCompleter.complete();
      });

      await _tts.speak(result.reply);

      // Wait for TTS to finish (30 s safety timeout).
      await ttsCompleter.future
          .timeout(const Duration(seconds: 30), onTimeout: () {});

      await _executeAction(result.action);

      _setState(VoiceState.idle);

      // Continuous conversation: automatically re-listen.
      if (_conversationOpen) {
        await Future.delayed(const Duration(milliseconds: 600));
        await startListening();
      }
    } catch (e) {
      _setError(e.toString());
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
          final today = DateFormat("yyyy-MM-dd").format(DateTime.now());
          final activeSession =
              await _session.api.fetchActiveSession().catchError((_) => null);
          await _session.api.createClimb({
            "difficulty": difficulty,
            if (routeName != null && routeName.isNotEmpty) "routeName": routeName,
            "date": today,
            "venue": activeSession?.venue ?? "未知场馆",
            "result": result,
            "attempts": attempts,
            if (notes != null && notes.isNotEmpty) "notes": notes,
            if (activeSession != null) "sessionId": activeSession.id,
          });

        case StartSessionAction(:final venue):
          await _session.api.startSession(venue);

        case EndSessionAction():
          final active =
              await _session.api.fetchActiveSession().catchError((_) => null);
          if (active != null) await _session.api.endSession(active.id);

        case QueryStatsAction():
          break; // Answer is already in the reply text.

        case NoAction():
          break;
      }
    } catch (_) {
      // Silently ignore action failures — the TTS reply already committed.
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
    _tts.stop();
    super.dispose();
  }
}
