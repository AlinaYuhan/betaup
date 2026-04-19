// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

/// Web Bluetooth implementation — delegates to web/ble_heart_rate.js
class BlePlatformImpl {
  static Object? _getBridge() {
    if (!kIsWeb) return null;
    try {
      return js_util.getProperty<Object?>(html.window, 'bleHeartRate');
    } catch (_) {
      return null;
    }
  }

  static bool get supported {
    final bridge = _getBridge();
    if (bridge == null) return false;
    try {
      return js_util.callMethod<bool>(bridge, 'isSupported', []);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> connectAndSubscribe({
    required void Function(int bpm) onBpm,
  }) async {
    final bridge = _getBridge();
    if (bridge == null) return false;
    try {
      final callback = js_util.allowInterop((dynamic bpm) {
        final v = (bpm as num).toInt();
        if (v > 0) onBpm(v);
      });
      final promise =
          js_util.callMethod<Object>(bridge, 'connect', [callback]);
      return await js_util.promiseToFuture<bool>(promise);
    } catch (_) {
      return false;
    }
  }

  static void disconnect() {
    final bridge = _getBridge();
    if (bridge == null) return;
    try {
      js_util.callMethod<void>(bridge, 'disconnect', []);
    } catch (_) {}
  }
}
