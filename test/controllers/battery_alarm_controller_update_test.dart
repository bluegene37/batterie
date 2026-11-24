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
  // Gene - Nov, 24, 2026: Added shouldThrow and openStoreCalled tracking for manual error and Store build tests.
  bool shouldThrow = false;
  bool openStoreCalled = false;

  FakeUpdateService({this.nextUpdate});

  // Gene - Nov, 24, 2026: Updated checkForUpdates mock to support throwOnError and added openMicrosoftStoreUpdates mock. Preserved previous checkForUpdates below.
  // @override
  // Future<UpdateInfo?> checkForUpdates() async {
  //   checkCalled = true;
  //   return nextUpdate;
  // }
  @override
  Future<UpdateInfo?> checkForUpdates({bool throwOnError = false}) async {
    checkCalled = true;
    if (shouldThrow && throwOnError) {
      throw Exception('Network error');
    }
    if (shouldThrow) {
      return null;
    }
    return nextUpdate;
  }

  @override
  Future<bool> openMicrosoftStoreUpdates() async {
    openStoreCalled = true;
    return true;
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

    // Gene - Nov, 24, 2026: Added regression tests for silent background checks, manual up-to-date dismissal, error retry/dismiss, Store build handling, and timer disposal safety.
    test('background checkForUpdates stays idle when already up to date', () async {
      final updateService = FakeUpdateService(nextUpdate: null);
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      await controller.checkForUpdates(manual: false);

      expect(updateService.checkCalled, isTrue);
      expect(controller.updateStatus, equals(UpdateStatus.idle));
      expect(controller.showUpdateBanner, isFalse);

      controller.dispose();
    });

    test('manual checkForUpdates sets upToDate and dismissUpdateBanner resets to idle', () async {
      final updateService = FakeUpdateService(nextUpdate: null);
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      await controller.checkForUpdates(manual: true);

      expect(controller.updateStatus, equals(UpdateStatus.upToDate));
      expect(controller.showUpdateBanner, isTrue);

      controller.dismissUpdateBanner();

      expect(controller.updateStatus, equals(UpdateStatus.idle));
      expect(controller.showUpdateBanner, isFalse);
      expect(controller.isUpdateBannerDismissed, isTrue);

      controller.dispose();
    });

    test('manual error state can be dismissed and retried via retryOrInstallUpdate', () async {
      final updateService = FakeUpdateService(nextUpdate: null)
        ..shouldThrow = true;
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      await controller.checkForUpdates(manual: true);

      expect(controller.updateStatus, equals(UpdateStatus.error));
      expect(controller.updateErrorMessage, isNotNull);
      expect(controller.showUpdateBanner, isTrue);

      controller.dismissUpdateBanner();
      expect(controller.updateStatus, equals(UpdateStatus.idle));
      expect(controller.updateErrorMessage, isNull);
      expect(controller.showUpdateBanner, isFalse);

      await controller.checkForUpdates(manual: true);
      expect(controller.updateStatus, equals(UpdateStatus.error));

      updateService
        ..checkCalled = false
        ..shouldThrow = false;
      await controller.retryOrInstallUpdate();

      expect(updateService.checkCalled, isTrue);
      expect(controller.updateStatus, equals(UpdateStatus.upToDate));

      controller.dispose();
    });

    test('Store builds do not auto-install and open Microsoft Store instead of downloading zip', () async {
      SharedPreferences.setMockInitialValues({
        'app_auto_update_enabled': true,
      });
      final storeUpdate = UpdateInfo(
        version: '1.0.5',
        tagName: 'v1.0.5',
        releaseUrl: 'https://example.com/release',
        assetUrl: 'https://example.com/batterie-windows-x64.zip',
        assetName: 'batterie-windows-x64.zip',
        isStoreBuild: true,
      );
      final updateService = FakeUpdateService(nextUpdate: storeUpdate);
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      await controller.checkForUpdates(manual: true);

      expect(controller.updateStatus, equals(UpdateStatus.available));
      expect(updateService.downloadCalled, isFalse);
      expect(updateService.installCalled, isFalse);
      expect(updateService.openStoreCalled, isFalse);

      await controller.installUpdate();

      expect(updateService.openStoreCalled, isTrue);
      expect(updateService.downloadCalled, isFalse);
      expect(updateService.installCalled, isFalse);

      controller.dispose();
    });

    test('disposing controller cancels pending upToDate auto-reset timer cleanly', () async {
      final updateService = FakeUpdateService(nextUpdate: null);
      final controller = BatteryAlarmController(
        updateService: updateService,
        alarmService: FakeAlarmService(),
        settingsService: SettingsService(),
      );

      await controller.init();
      await controller.checkForUpdates(manual: true);
      expect(controller.updateStatus, equals(UpdateStatus.upToDate));

      expect(() => controller.dispose(), returnsNormally);
    });
  });
}
