import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/models/alarm_state.dart';
import 'package:batterie/models/battery_info.dart';
import 'package:batterie/models/threshold_rule.dart';
import 'package:batterie/theme/app_theme.dart';
import 'package:batterie/ui/widgets/alarm_takeover.dart';

void main() {
  const rule = ThresholdRule(id: 'r', percentage: 10, label: 'Critical Alert');
  const info = BatteryInfo(percentage: 9, isCharging: false, source: PowerSource.battery);

  Widget build({
    Brightness brightness = Brightness.light,
    bool disableAnimations = false,
    double textScale = 1.0,
  }) {
    return MaterialApp(
      theme: AppTheme.buildTheme(brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: AlarmTakeover(
          alarmState: AlarmState.ringing(rule),
          batteryInfo: info,
          snoozeMinutes: 5,
          onSnooze: () {},
          onDismiss: () {},
        ),
      ),
    );
  }

  testWidgets('Title is announced as a live-region header for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(build());
    await tester.pump();

    final title = tester.getSemantics(find.text('BATTERY ALARM TRIGGERED!'));
    expect(title.flagsCollection.isHeader, isTrue);
    expect(title.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('Warning icon is decorative and hidden from screen readers', (tester) async {
    await tester.pumpWidget(build());
    await tester.pump();

    final icon = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == Icons.warning_amber_rounded,
    );
    expect(icon, findsOneWidget);
    expect(find.ancestor(of: icon, matching: find.byType(ExcludeSemantics)), findsWidgets);
  });

  testWidgets('Pulse stops when the platform asks for reduced motion', (tester) async {
    await tester.pumpWidget(build(disableAnimations: true));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, equals(0));
  });

  testWidgets('Layout survives 2x text scale without overflow', (tester) async {
    await tester.pumpWidget(build(textScale: 2.0));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Snooze (5m)'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
  });

  test('Both ends of the pulse keep AA contrast (4.5:1) with the alarm text', () {
    double channel(double v) =>
        v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    double lum(Color c) => 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
    double ratio(Color a, Color b) {
      final la = lum(a), lb = lum(b);
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    for (final brightness in Brightness.values) {
      final scheme = AppTheme.buildTheme(brightness: brightness).colorScheme;
      expect(ratio(scheme.error, scheme.onError), greaterThanOrEqualTo(4.5),
          reason: '$brightness error vs onError');
      expect(ratio(scheme.errorContainer, scheme.onError), greaterThanOrEqualTo(4.5),
          reason: '$brightness errorContainer vs onError');
      expect(ratio(scheme.onSurface, scheme.surface), greaterThanOrEqualTo(4.5),
          reason: '$brightness body text on cards');
      expect(ratio(scheme.onSurfaceVariant, scheme.surface), greaterThanOrEqualTo(4.5),
          reason: '$brightness secondary text on cards');
      expect(ratio(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5),
          reason: '$brightness button text on accent');
    }
  });
}
