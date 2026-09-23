import 'package:batterie/ui/widgets/audio_settings_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AudioSettingsCard renders repeat count and triggers callback on change',
      (tester) async {
    int? updatedRepeatCount;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AudioSettingsCard(
              selectedSound: 'siren',
              volume: 0.8,
              snoozeMinutes: 5,
              repeatCount: 3,
              isTesting: false,
              onSoundChanged: (_) {},
              onCustomPathChanged: (_) {},
              onVolumeChanged: (_) {},
              onSnoozeChanged: (_) {},
              onRepeatCountChanged: (count) {
                updatedRepeatCount = count;
              },
              onTestAlarm: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and label
    expect(find.text('Repeat Alarm:'), findsOneWidget);
    expect(find.text('3 times'), findsOneWidget);

    // Tap repeat dropdown and select '1 time'
    await tester.tap(find.text('3 times'));
    await tester.pumpAndSettle();

    expect(find.text('1 time'), findsWidgets);
    expect(find.text('Continuous'), findsOneWidget);

    await tester.tap(find.text('1 time').last);
    await tester.pumpAndSettle();

    expect(updatedRepeatCount, equals(1));
  });
}
