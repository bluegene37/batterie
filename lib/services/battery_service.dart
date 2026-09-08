import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart' as bp;
import 'package:flutter/foundation.dart';
import '../models/battery_info.dart';

class BatteryService {
  final bp.Battery _batteryPlugin;
  Timer? _timer;
  final _controller = StreamController<BatteryInfo>.broadcast();
  BatteryInfo _lastKnown = const BatteryInfo(
    percentage: 100,
    isCharging: true,
    source: PowerSource.ac,
  );
  bool _isDisposed = false;

  BatteryService({bp.Battery? batteryPlugin})
      : _batteryPlugin = batteryPlugin ?? bp.Battery() {
    _init();
  }

  BatteryInfo get currentInfo => _lastKnown;
  Stream<BatteryInfo> get onBatteryChanged => _controller.stream;

  void _init() {
    // Listen for OS battery state transitions (plug/unplug)
    try {
      _batteryPlugin.onBatteryStateChanged.listen(
        (_) {
          fetchBatteryInfo();
        },
        onError: (err) {
          debugPrint('BatteryState stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('BatteryState listen not supported on this platform: $e');
    }

    // Immediate initial poll
    fetchBatteryInfo();
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _timer?.cancel();
    if (_isDisposed) return;

    // Adaptive interval: 5 seconds if discharging, 20 seconds if on AC
    final duration = _lastKnown.isDischarging
        ? const Duration(seconds: 5)
        : const Duration(seconds: 20);

    _timer = Timer(duration, () async {
      await fetchBatteryInfo();
      _scheduleNextPoll();
    });
  }

  Future<BatteryInfo> fetchBatteryInfo() async {
    BatteryInfo? info;

    if (Platform.isMacOS) {
      info = await _getMacOsBatteryInfo();
    } else if (Platform.isWindows) {
      info = await _getWindowsBatteryInfo();
    }

    // Fallback to battery_plus plugin
    info ??= await _getPluginBatteryInfo();

    _lastKnown = info;
    if (!_controller.isClosed) {
      _controller.add(info);
    }
    return info;
  }

  Future<BatteryInfo?> _getMacOsBatteryInfo() async {
    try {
      final result = await Process.run('pmset', ['-g', 'batt']);
      if (result.exitCode == 0) {
        return parsePmsetOutput(result.stdout.toString());
      }
    } catch (e) {
      debugPrint('Error running pmset: $e');
    }
    return null;
  }

  Future<BatteryInfo?> _getWindowsBatteryInfo() async {
    try {
      final result = await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          'Get-CimInstance -ClassName Win32_Battery | Select-Object -Property EstimatedChargeRemaining, BatteryStatus',
        ],
      );
      if (result.exitCode == 0) {
        return parseWindowsCimOutput(result.stdout.toString());
      }
    } catch (e) {
      debugPrint('Error querying Windows battery: $e');
    }
    return null;
  }

  Future<BatteryInfo> _getPluginBatteryInfo() async {
    int level = 100;
    bool isCharging = true;
    try {
      level = await _batteryPlugin.batteryLevel;
      final state = await _batteryPlugin.batteryState;
      isCharging = (state == bp.BatteryState.charging ||
          state == bp.BatteryState.full);
    } catch (e) {
      debugPrint('Battery plugin error: $e');
    }

    return BatteryInfo(
      percentage: level,
      isCharging: isCharging,
      source: isCharging ? PowerSource.ac : PowerSource.battery,
    );
  }

  static BatteryInfo? parsePmsetOutput(String output) {
    if (output.trim().isEmpty) return null;

    final percentMatch = RegExp(r'(\d+)%').firstMatch(output);
    if (percentMatch == null) return null;
    final percentage = int.tryParse(percentMatch.group(1) ?? '') ?? 100;

    final lower = output.toLowerCase();
    final isDischarging = lower.contains('discharging');
    final isAc = lower.contains('ac power');
    final isCharging = !isDischarging &&
        (lower.contains('charging') || lower.contains('charged') || isAc);

    final timeMatch = RegExp(r'(\d+:\d+)\s+remaining').firstMatch(output);
    final remaining = timeMatch?.group(1);

    return BatteryInfo(
      percentage: percentage,
      isCharging: isCharging,
      source: isAc ? PowerSource.ac : PowerSource.battery,
      timeRemaining: remaining,
    );
  }

  static BatteryInfo? parseWindowsCimOutput(String output) {
    if (output.trim().isEmpty) return null;

    final chargeMatch = RegExp(r'EstimatedChargeRemaining\s*:\s*(\d+)').firstMatch(output);
    if (chargeMatch == null) return null;
    final percentage = int.tryParse(chargeMatch.group(1) ?? '') ?? 100;

    final statusMatch = RegExp(r'BatteryStatus\s*:\s*(\d+)').firstMatch(output);
    final statusCode = int.tryParse(statusMatch?.group(1) ?? '') ?? 1;

    // BatteryStatus: 1 = Discharging, 2 = Unknown/AC connected, 3 = Fully Charged, 6 = Charging
    final isCharging = statusCode != 1;

    return BatteryInfo(
      percentage: percentage,
      isCharging: isCharging,
      source: isCharging ? PowerSource.ac : PowerSource.battery,
    );
  }

  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _controller.close();
  }
}
