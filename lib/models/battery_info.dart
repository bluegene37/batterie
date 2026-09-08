enum PowerSource {
  battery,
  ac,
  unknown,
}

class BatteryInfo {
  final int percentage;
  final bool isCharging;
  final PowerSource source;
  final String? timeRemaining;

  const BatteryInfo({
    required this.percentage,
    required this.isCharging,
    this.source = PowerSource.battery,
    this.timeRemaining,
  });

  bool get isDischarging => !isCharging && source != PowerSource.ac;

  String get statusText {
    final state = isCharging ? 'Charging' : 'Discharging';
    final remaining = (timeRemaining != null && timeRemaining!.isNotEmpty)
        ? ' ($timeRemaining remaining)'
        : '';
    return '$state ($percentage%)$remaining';
  }

  BatteryInfo copyWith({
    int? percentage,
    bool? isCharging,
    PowerSource? source,
    String? timeRemaining,
  }) {
    return BatteryInfo(
      percentage: percentage ?? this.percentage,
      isCharging: isCharging ?? this.isCharging,
      source: source ?? this.source,
      timeRemaining: timeRemaining ?? this.timeRemaining,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BatteryInfo &&
        other.percentage == percentage &&
        other.isCharging == isCharging &&
        other.source == source;
  }

  @override
  int get hashCode => Object.hash(percentage, isCharging, source);
}
