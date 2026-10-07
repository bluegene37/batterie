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

  // Gene - Oct, 07, 2026: Added test verifying AudioSettingsCard dropdown updates when switching from custom to preset
  testWidgets('AudioSettingsCard updates dropdown when selectedSound changes from custom to preset', (tester) async {
    String currentSound = 'custom';
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: AudioSettingsCard(
              selectedSound: currentSound,
              customSoundPath: '/tmp/test.mp3',
              volume: 0.8,
              snoozeMinutes: 5,
              repeatCount: 3,
              isTesting: false,
              onSoundChanged: (sound) => setState(() => currentSound = sound),
              onCustomPathChanged: (_) {},
              onVolumeChanged: (_) {},
              onSnoozeChanged: (_) {},
              onRepeatCountChanged: (_) {},
              onTestAlarm: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Custom Audio File…'), findsOneWidget);

    // Tap dropdown and select 'Digital Alarm'
    await tester.tap(find.text('Custom Audio File…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Digital Alarm').last);
    await tester.pumpAndSettle();

    expect(currentSound, equals('digital'));
    expect(find.text('Digital Alarm'), findsOneWidget);
  });
}
