import 'dart:async';
import 'dart:js_interop';

@JS('window')
external _SpeechWindow get _window;

extension type _SpeechWindow(JSObject _) implements JSObject {
  external _SpeechSynthesis? get speechSynthesis;
}

extension type _SpeechSynthesis(JSObject _) implements JSObject {
  external void speak(_SpeechSynthesisUtterance utterance);
  external void cancel();
}

@JS('SpeechSynthesisUtterance')
extension type _SpeechSynthesisUtterance._(JSObject _) implements JSObject {
  external factory _SpeechSynthesisUtterance(String text);
  external set lang(String value);
  external set rate(double value);
  external set volume(double value);
  external set onend(JSFunction? callback);
  external set onerror(JSFunction? callback);
}

class VoiceSpeechBridge {
  static Future<void> speak(String text) async {
    final synth = _window.speechSynthesis;
    if (synth == null) {
      return;
    }

    synth.cancel();
    final utterance = _SpeechSynthesisUtterance(text)
      ..lang = 'zh-CN'
      ..rate = 0.85
      ..volume = 1.0;

    final completer = Completer<void>();
    final onComplete = (() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS;

    utterance.onend = onComplete;
    utterance.onerror = onComplete;
    synth.speak(utterance);
    await completer.future;
  }

  static void stop() {
    _window.speechSynthesis?.cancel();
  }
}
