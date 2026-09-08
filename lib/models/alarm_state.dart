import 'threshold_rule.dart';

enum AlarmStatus {
  idle,
  ringing,
  snoozed,
}

class AlarmState {
  final AlarmStatus status;
  final ThresholdRule? triggeredRule;
  final DateTime? snoozeUntil;

  const AlarmState({
    required this.status,
    this.triggeredRule,
    this.snoozeUntil,
  });

  factory AlarmState.idle() {
    return const AlarmState(status: AlarmStatus.idle);
  }

  factory AlarmState.ringing(ThresholdRule rule) {
    return AlarmState(
      status: AlarmStatus.ringing,
      triggeredRule: rule,
    );
  }

  AlarmState toSnoozed(DateTime until) {
    return AlarmState(
      status: AlarmStatus.snoozed,
      triggeredRule: triggeredRule,
      snoozeUntil: until,
    );
  }

  bool get isRinging => status == AlarmStatus.ringing;
  bool get isSnoozed => status == AlarmStatus.snoozed;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlarmState &&
        other.status == status &&
        other.triggeredRule == triggeredRule &&
        other.snoozeUntil == snoozeUntil;
  }

  @override
  int get hashCode => Object.hash(status, triggeredRule, snoozeUntil);
}
