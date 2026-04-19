/// Stub implementation for unsupported platforms.
class BlePlatformImpl {
  static bool get supported => false;

  static Future<bool> connectAndSubscribe({
    required void Function(int bpm) onBpm,
  }) async =>
      false;

  static void disconnect() {}
}
