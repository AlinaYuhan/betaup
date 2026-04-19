import 'dart:async';
import 'dart:math';

// Platform-specific BLE implementation (BlePlatformImpl):
//   Web  → heart_rate_ble_web.dart  (dart:html + JS bridge)
//   iOS  → heart_rate_ble_io.dart   (flutter_blue_plus)
//   Other→ heart_rate_ble_stub.dart (no-op)
import 'heart_rate_ble_stub.dart'
    if (dart.library.html) 'heart_rate_ble_web.dart'
    if (dart.library.io) 'heart_rate_ble_io.dart';

/// A single heart rate sample captured from Apple Watch.
class HeartRateSample {
  final DateTime time;
  final int bpm;
  const HeartRateSample({required this.time, required this.bpm});
}

/// Public API — delegates BLE work to the platform-specific BlePlatformImpl.
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

  // ── Stats helpers ────────────────────────────────────────────────────────

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

// ── Mock Heart Rate Simulator ─────────────────────────────────────────────────
/// Generates realistic climbing-session heart rate data for demo / web testing.
/// Simulates: warmup → climbing bursts (130–160 bpm) → rest (90–110 bpm).
class MockHeartRateSimulator {
  static Timer? _timer;
  static int _tick = 0;
  static final _rng = Random();

  static bool get isRunning => _timer != null;

  static void start({required void Function(HeartRateSample) onSample}) {
    stop();
    _tick = 0;
    _emit(onSample);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _emit(onSample));
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _tick = 0;
  }

  static void _emit(void Function(HeartRateSample) onSample) {
    _tick++;
    onSample(HeartRateSample(time: DateTime.now(), bpm: _nextBpm()));
  }

  static int _nextBpm() {
    final t = _tick * 3 / 60.0;
    final base = 72.0 + (t * 15).clamp(0.0, 38.0);
    final cycle = (t % 2.5) / 2.5;
    final burst = cycle < 0.45
        ? 55.0 * sin(cycle / 0.45 * pi)
        : 18.0 * (1.0 - (cycle - 0.45) / 0.55);
    final noise = (_rng.nextDouble() - 0.5) * 10.0;
    return (base + burst + noise).round().clamp(68, 172);
  }
}
