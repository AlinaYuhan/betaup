import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// iOS / Android BLE implementation via flutter_blue_plus.
/// Scans for a device advertising the Heart Rate service (0x180D),
/// connects, and subscribes to the Heart Rate Measurement characteristic (0x2A37).
class BlePlatformImpl {
  static BluetoothDevice? _device;
  static StreamSubscription<dynamic>? _scanSub;
  static StreamSubscription<dynamic>? _notifySub;

  static const _hrSvcUuid  = '0000180d-0000-1000-8000-00805f9b34fb';
  static const _hrCharUuid = '00002a37-0000-1000-8000-00805f9b34fb';

  static bool get supported => true;

  static Future<bool> connectAndSubscribe({
    required void Function(int bpm) onBpm,
  }) async {
    try {
      disconnect();

      // Make sure Bluetooth is on
      final adapterState =
          await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => BluetoothAdapterState.unknown,
      );
      if (adapterState != BluetoothAdapterState.on) return false;

      final completer = Completer<bool>();

      // Scan for devices advertising the Heart Rate service
      await FlutterBluePlus.startScan(
        withServices: [Guid(_hrSvcUuid)],
        timeout: const Duration(seconds: 15),
      );

      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        if (results.isEmpty || completer.isCompleted) return;

        final result = results.first;
        _device = result.device;

        await FlutterBluePlus.stopScan();
        _scanSub?.cancel();

        // Connect
        await _device!.connect(autoConnect: false);
        final services = await _device!.discoverServices();

        final hrSvc = services
            .where((s) =>
                s.serviceUuid.toString().toLowerCase().contains('180d'))
            .firstOrNull;
        if (hrSvc == null) {
          if (!completer.isCompleted) completer.complete(false);
          return;
        }

        final hrChr = hrSvc.characteristics
            .where((c) =>
                c.characteristicUuid.toString().toLowerCase().contains('2a37'))
            .firstOrNull;
        if (hrChr == null) {
          if (!completer.isCompleted) completer.complete(false);
          return;
        }

        await hrChr.setNotifyValue(true);
        _notifySub = hrChr.lastValueStream.listen((data) {
          if (data.isEmpty) return;
          final flags = data[0];
          final bpm = (flags & 0x01) != 0
              ? data[1] | (data[2] << 8)
              : data[1];
          if (bpm > 0) onBpm(bpm);
        });

        if (!completer.isCompleted) completer.complete(true);
      });

      // When scan ends without finding a device
      FlutterBluePlus.isScanning
          .where((scanning) => !scanning)
          .first
          .then((_) {
        if (!completer.isCompleted) completer.complete(false);
      });

      return completer.future;
    } catch (_) {
      return false;
    }
  }

  static void disconnect() {
    _scanSub?.cancel();
    _scanSub = null;
    _notifySub?.cancel();
    _notifySub = null;
    try {
      _device?.disconnect();
    } catch (_) {}
    _device = null;
    try {
      FlutterBluePlus.stopScan();
    } catch (_) {}
  }
}
