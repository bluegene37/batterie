// Gene - Oct 24, 2026: Tests for controller auto-update check, download, install gating, and persistence.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batterie/controllers/battery_alarm_controller.dart';
import 'package:batterie/models/update_info.dart';
import 'package:batterie/services/alarm_service.dart';
import 'package:batterie/services/settings_service.dart';
import 'package:batterie/services/update_service.dart';

class FakeUpdateService extends UpdateService {
  UpdateInfo? nextUpdate;
  bool checkCalled = false;
  bool downloadCalled = false;
  bool installCalled = false;

  FakeUpdateService({this.nextUpdate});

  @override
  Future<UpdateInfo?> checkForUpdates() async {
    checkCalled = true;
    return nextUpdate;
  }

  @override
  Future<File> downloadReleaseAsset(
    UpdateInfo updateInfo, {
    void Function(double progress)? onProgress,
  }) async {
    downloadCalled = true;
    onProgress?.call(0.5);
    onProgress?.call(1.0);
    return File('/tmp/fake_asset.zip');
  }

  @override
  Future<bool> installUpdate(File downloadedFile) async {
    installCalled = true;
    return true;
  }
}

class FakeAlarmService extends AlarmService {
  bool ringing = false;
  @override
  bool get isRinging => ringing;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_auto_update_enabled': false, // start false for controlled manual testing
    });
  });

  group('BatteryAlarmController Update Tests', () {
    test('checkForUpdates updates controller state when new update is available', () async {
      final fakeUpdate = UpdateInfo(
        version: '1.0.4',
        tagName: 'v1.0.4',
        releaseUrl: 'https://example.com',
        assetUrl: 'https://example.com/batterie-macos.zip',
        assetName: 'batterie-macos.zip',
      );
      final updateService = FakeUpdateService(nextUpdate: fakeUpdate);
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      expect(controller.autoUpdateEnabled, isFalse);
      expect(controller.updateStatus, equals(UpdateStatus.idle));

      await controller.checkForUpdates();

      expect(updateService.checkCalled, isTrue);
      expect(controller.updateStatus, equals(UpdateStatus.available));
      expect(controller.updateInfo, equals(fakeUpdate));
      expect(controller.hasUpdateAvailable, isTrue);

      controller.dispose();
    });

    test('dismissUpdateBanner marks hasUpdateAvailable as false', () async {
      final fakeUpdate = UpdateInfo(
        version: '1.0.4',
        tagName: 'v1.0.4',
        releaseUrl: 'https://example.com',
        assetUrl: 'https://example.com/asset.zip',
        assetName: 'asset.zip',
      );
      final updateService = FakeUpdateService(nextUpdate: fakeUpdate);
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      await controller.checkForUpdates();
      expect(controller.hasUpdateAvailable, isTrue);

      controller.dismissUpdateBanner();
      expect(controller.hasUpdateAvailable, isFalse);
      expect(controller.isUpdateBannerDismissed, isTrue);

      controller.dispose();
    });

    test('installUpdate downloads and installs update when not ringing', () async {
      final fakeUpdate = UpdateInfo(
        version: '1.0.4',
        tagName: 'v1.0.4',
        releaseUrl: 'https://example.com',
        assetUrl: 'https://example.com/asset.zip',
        assetName: 'asset.zip',
      );
      final updateService = FakeUpdateService(nextUpdate: fakeUpdate);
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      await controller.checkForUpdates();

      await controller.installUpdate();

      expect(updateService.downloadCalled, isTrue);
      expect(updateService.installCalled, isTrue);
      expect(controller.updateStatus, equals(UpdateStatus.installing));

      controller.dispose();
    });

    test('setAutoUpdateEnabled saves preference and auto-installs if update is waiting', () async {
      final fakeUpdate = UpdateInfo(
        version: '1.0.4',
        tagName: 'v1.0.4',
        releaseUrl: 'https://example.com',
        assetUrl: 'https://example.com/asset.zip',
        assetName: 'asset.zip',
      );
      final updateService = FakeUpdateService(nextUpdate: fakeUpdate);
      final settingsService = SettingsService();
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: settingsService,
      );

      await controller.init();
      await controller.checkForUpdates();
      expect(updateService.installCalled, isFalse);

      await controller.setAutoUpdateEnabled(true);
      expect(controller.autoUpdateEnabled, isTrue);
      expect(updateService.installCalled, isTrue);

      final saved = await settingsService.loadAutoUpdateEnabled();
      expect(saved, isTrue);

      controller.dispose();
    });
  });
}
