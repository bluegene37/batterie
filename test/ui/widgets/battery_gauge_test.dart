import 'package:batterie/models/battery_info.dart';
import 'package:batterie/ui/widgets/battery_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(BatteryInfo info, {double width = 380}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BatteryGauge(info: info),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('does not overflow with long status text at window width',
      (tester) async {
    await tester.pumpWidget(host(const BatteryInfo(
      percentage: 100,
      isCharging: false,
      timeRemaining: '12:34',
    )));
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at minimum window width while charging',
      (tester) async {
    await tester.pumpWidget(host(
      const BatteryInfo(
        percentage: 100,
        isCharging: true,
        timeRemaining: '12:34',
      ),
      width: 340,
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('100%'), findsOneWidget);
  });
}
