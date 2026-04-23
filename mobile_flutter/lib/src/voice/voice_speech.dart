import 'voice_speech_stub.dart'
    if (dart.library.js_interop) 'voice_speech_web.dart';

Future<void> speakText(String text) => VoiceSpeechBridge.speak(text);

void stopSpeaking() => VoiceSpeechBridge.stop();
