import 'dart:async';
import 'dart:math';

// Platform-specific BLE implementation (BlePlatformImpl):
//   Web   -> heart_rate_ble_web.dart  (JS bridge)
//   iOS   -> heart_rate_ble_io.dart   (flutter_blue_plus)
//   Other -> heart_rate_ble_stub.dart (no-op)
import 'heart_rate_ble_stub.dart'
    if (dart.library.html) 'heart_rate_ble_web.dart'
    if (dart.library.io) 'heart_rate_ble_io.dart';

/// A single heart rate sample captured from Apple Watch.
class HeartRateSample {
  final DateTime time;
  final int bpm;

  const HeartRateSample({required this.time, required this.bpm});
}

/// Public API that delegates BLE work to the platform-specific BlePlatformImpl.
class BleHeartRateService {
  static bool get supported => BlePlatformImpl.supported;

  /// Opens Bluetooth picker (web) or scans for Watch (iOS), then subscribes.
  static Future<bool> connectAndSubscribe({
    required void Function(HeartRateSample sample) onSample,
  }) =>
      BlePlatformImpl.connectAndSubscribe(
        onBpm: (bpm) =>
            onSample(HeartRateSample(time: DateTime.now(), bpm: bpm)),
      );

  static void disconnect() => BlePlatformImpl.disconnect();

  static int averageBpm(List<HeartRateSample> samples) {
    if (samples.isEmpty) return 0;
    return (samples.map((s) => s.bpm).reduce((a, b) => a + b) /
            samples.length)
        .round();
  }

  static int maxBpm(List<HeartRateSample> samples) {
    if (samples.isEmpty) return 0;
    return samples.map((s) => s.bpm).reduce((a, b) => a > b ? a : b);
  }

  static int minBpm(List<HeartRateSample> samples) {
    if (samples.isEmpty) return 0;
    return samples.map((s) => s.bpm).reduce((a, b) => a < b ? a : b);
  }
}

/// Generates realistic climbing-session heart rate data for demo / web testing.
/// Simulates: warmup -> climbing bursts (130-160 bpm) -> rest (90-110 bpm).
class MockHeartRateSimulator {
  static Timer? _timer;

  static bool get isRunning => _timer != null;

  static void start({required void Function(HeartRateSample) onSample}) {
    stop();
    _emit(onSample);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _emit(onSample));
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static void _emit(void Function(HeartRateSample) onSample) {
    onSample(HeartRateSample(time: DateTime.now(), bpm: _nextBpm()));
  }

  static int _nextBpm() {
    // Clock-based formula — identical to the watch simulation in demo.html.
    // Both read wall-clock milliseconds so they always display the same BPM.
    final ms = DateTime.now().millisecondsSinceEpoch;
    return (128 + 15 * sin(ms / 8000 * 2 * pi)).round().clamp(68, 172);
  }
}
