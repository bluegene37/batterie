// Gene - Oct 24, 2026: Widget tests for UpdateBanner UI, progress display, and action callbacks.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/models/update_info.dart';
import 'package:batterie/ui/widgets/update_banner.dart';

void main() {
  final testUpdate = UpdateInfo(
    version: '1.0.4',
    tagName: 'v1.0.4',
    releaseUrl: 'https://example.com/release',
    assetUrl: 'https://example.com/batterie-macos.zip',
    assetName: 'batterie-macos.zip',
  );

  testWidgets('UpdateBanner renders nothing when idle and update is null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateBanner(
            updateInfo: null,
            status: UpdateStatus.idle,
            progress: 0.0,
            onUpdate: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.byType(UpdateBanner), findsOneWidget);
    expect(find.textContaining('Update'), findsNothing);
  });

  testWidgets('UpdateBanner renders available state and triggers onUpdate callback', (tester) async {
    bool updatePressed = false;
    bool dismissPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateBanner(
            updateInfo: testUpdate,
            status: UpdateStatus.available,
            progress: 0.0,
            onUpdate: () {
              updatePressed = true;
            },
            onDismiss: () {
              dismissPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Update Available (v1.0.4)'), findsOneWidget);
    expect(find.text('Update & Restart'), findsOneWidget);

    await tester.tap(find.text('Update & Restart'));
    await tester.pump();
    expect(updatePressed, isTrue);

    await tester.tap(find.byTooltip('Dismiss'));
    await tester.pump();
    expect(dismissPressed, isTrue);
  });

  testWidgets('UpdateBanner renders downloading state with progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateBanner(
            updateInfo: testUpdate,
            status: UpdateStatus.downloading,
            progress: 0.65,
            onUpdate: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('Downloading Update v1.0.4'), findsOneWidget);
    expect(find.text('65% completed'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('UpdateBanner renders error state with retry button', (tester) async {
    bool retryPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateBanner(
            updateInfo: testUpdate,
            status: UpdateStatus.error,
            progress: 0.0,
            errorMessage: 'Network timeout during download',
            onUpdate: () {
              retryPressed = true;
            },
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('Update Failed'), findsOneWidget);
    expect(find.text('Network timeout during download'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retryPressed, isTrue);
  });
}
