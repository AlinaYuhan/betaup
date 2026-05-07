/// Stub implementation for unsupported platforms.
class BlePlatformImpl {
  static bool get supported => false;
  static int? get overrideBpm => null;

  static Future<bool> connectAndSubscribe({
    required void Function(int bpm) onBpm,
  }) async =>
      false;

  static void disconnect() {}
}
