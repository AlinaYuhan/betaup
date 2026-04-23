import 'dart:js_interop';

@JS('window')
external _BleWindow get _window;

extension type _BleWindow(JSObject _) implements JSObject {
  external JSAny? get bleHeartRate;
}

extension type _BleBridge(JSObject _) implements JSObject {
  external JSBoolean isSupported();
  external JSPromise<JSBoolean> connect(JSFunction onBpm);
  external void disconnect();
}

/// Web Bluetooth implementation delegated to `web/ble_heart_rate.js`.
class BlePlatformImpl {
  static _BleBridge? _getBridge() {
    final bridge = _window.bleHeartRate;
    if (bridge == null) {
      return null;
    }
    return bridge as _BleBridge;
  }

  static bool get supported {
    final bridge = _getBridge();
    if (bridge == null) {
      return false;
    }

    try {
      return bridge.isSupported().toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> connectAndSubscribe({
    required void Function(int bpm) onBpm,
  }) async {
    final bridge = _getBridge();
    if (bridge == null) {
      return false;
    }

    try {
      final callback = ((JSNumber bpm) {
        final value = bpm.toDartInt;
        if (value > 0) {
          onBpm(value);
        }
      }).toJS;
      final connected = await bridge.connect(callback).toDart;
      return connected.toDart;
    } catch (_) {
      return false;
    }
  }

  static void disconnect() {
    final bridge = _getBridge();
    if (bridge == null) {
      return;
    }

    try {
      bridge.disconnect();
    } catch (_) {}
  }
}
