import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/models/threshold_rule.dart';
import 'package:batterie/theme/app_theme.dart';
import 'package:batterie/ui/widgets/threshold_list.dart';

void main() {
  const rule = ThresholdRule(
    id: 'r1',
    percentage: 20,
    label: 'Warning',
    soundType: 'siren',
  );

  Future<void> pumpList(
    WidgetTester tester, {
    List<ThresholdRule> rules = const [rule],
    String defaultSound = 'siren',
    void Function(int, String, String, String?)? onAdd,
    void Function(ThresholdRule)? onUpdate,
    void Function(String, String?)? onPreview,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ThresholdList(
              rules: rules,
              defaultSound: defaultSound,
              onAdd: onAdd ?? (_, _, _, _) {},
              onUpdate: onUpdate ?? (_) {},
              onDelete: (_) {},
              onPreview: onPreview ?? (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseSound(WidgetTester tester, String optionText) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(optionText).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Edit dialog lets the user change the alarm sound of a rule', (tester) async {
    ThresholdRule? saved;
    await pumpList(tester, onUpdate: (r) => saved = r);

    await tester.tap(find.byTooltip('Edit threshold'));
    await tester.pumpAndSettle();

    expect(find.text('Alarm Sound'), findsOneWidget);
    await chooseSound(tester, 'Alert Bell');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.id, equals('r1'));
    expect(saved!.soundType, equals('bell'));
    expect(saved!.percentage, equals(20));
  });

  testWidgets('Add dialog defaults to the global sound and passes the chosen sound', (tester) async {
    String? addedSound;
    int? addedPercentage;
    await pumpList(
      tester,
      defaultSound: 'digital',
      onAdd: (p, _, sound, _) {
        addedPercentage = p;
        addedSound = sound;
      },
    );

    await tester.tap(find.text('Add Threshold'));
    await tester.pumpAndSettle();

    // Default selection mirrors the global sound.
    expect(find.text('Digital Alarm'), findsOneWidget);

    await chooseSound(tester, 'Alert Bell');
    await tester.tap(find.text('Add Threshold').last);
    await tester.pumpAndSettle();

    expect(addedPercentage, equals(15));
    expect(addedSound, equals('bell'));
  });

  testWidgets('Preview button plays the sound currently selected in the dialog', (tester) async {
    String? previewed;
    await pumpList(tester, onPreview: (sound, _) => previewed = sound);

    await tester.tap(find.byTooltip('Edit threshold'));
    await tester.pumpAndSettle();

    await chooseSound(tester, 'Digital Alarm');
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    expect(previewed, equals('digital'));
  });

  testWidgets('Row subtitle names the sound of each rule', (tester) async {
    await pumpList(
      tester,
      rules: const [
        ThresholdRule(id: 'a', percentage: 20, label: 'A', soundType: 'bell'),
        ThresholdRule(id: 'b', percentage: 10, label: 'B', soundType: 'custom', customSoundPath: '/tmp/horn.mp3'),
      ],
    );

    expect(find.text('Alarm: Alert Bell'), findsOneWidget);
    expect(find.text('Alarm: horn.mp3'), findsOneWidget);
  });

  testWidgets('Stepper buttons give a non-drag way to change the percentage', (tester) async {
    ThresholdRule? saved;
    await pumpList(tester, onUpdate: (r) => saved = r);

    await tester.tap(find.byTooltip('Edit threshold'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Increase percentage'));
    await tester.tap(find.byTooltip('Increase percentage'));
    await tester.tap(find.byTooltip('Decrease percentage'));
    await tester.pumpAndSettle();
    expect(find.text('21%'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved!.percentage, equals(21));
  });

  testWidgets('Enable switch is labelled with the rule name for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpList(tester);

    final toggle = tester.getSemantics(find.byType(Switch));
    expect(toggle.label, contains('Warning'));
    expect(toggle.flagsCollection.isToggled, equals(Tristate.isTrue));
    handle.dispose();
  });

  testWidgets('Percentage badge does not clip at 2x text scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ThresholdList(
              rules: const [rule],
              onAdd: (_, _, _, _) {},
              onUpdate: (_) {},
              onDelete: (_) {},
              onPreview: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
