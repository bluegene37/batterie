import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../models/battery_info.dart';

class TrayWindowService with TrayListener, WindowListener {
  VoidCallback? _onShow;
  VoidCallback? _onTest;
  VoidCallback? _onQuit;
  bool _isInitialized = false;

  Future<void> init({
    required VoidCallback onShow,
    required VoidCallback onTest,
    required VoidCallback onQuit,
  }) async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return;
    }

    _onShow = onShow;
    _onTest = onTest;
    _onQuit = onQuit;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      final windowOptions = WindowOptions(
        size: const Size(380, 600),
        minimumSize: const Size(340, 520),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        title: 'Batterie',
        // On macOS the window is frosted glass; hiding the title bar lets the
        // glass run edge to edge under the traffic lights.
        titleBarStyle:
            Platform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
        windowButtonVisibility: true,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setPreventClose(true);
        await windowManager.show();
        await windowManager.focus();
      });

      trayManager.addListener(this);
      await _setupTrayIcon(false);
      await _updateContextMenu();

      _isInitialized = true;
    } catch (e) {
      debugPrint('TrayWindowService init error: $e');
    }
  }

  Future<void> _setupTrayIcon(bool isRinging) async {
    try {
      final iconPath = isRinging
          ? 'assets/icons/tray_icon_ringing.png'
          : 'assets/icons/tray_icon.png';
      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('Battery Alarm Monitor');
    } catch (e) {
      debugPrint('Error setting tray icon: $e');
    }
  }

  Future<void> _updateContextMenu({String? batterySummary}) async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'status',
          label: batterySummary ?? 'Batterie: Monitoring',
          disabled: true,
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'show_app',
          label: 'Show Dashboard',
        ),
        MenuItem(
          key: 'hide_app',
          label: 'Hide to Menu Bar',
        ),
        MenuItem(
          key: 'test_alarm',
          label: 'Test Alarm Sound',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit_app',
          label: 'Quit',
        ),
      ],
    );
    try {
      await trayManager.setContextMenu(menu);
    } catch (e) {
      debugPrint('Error setting context menu: $e');
    }
  }

  Future<void> updateTray(BatteryInfo info, bool isRinging) async {
    if (!_isInitialized) return;
    try {
      final summary = '${info.statusText} ${isRinging ? "[ALARM RINGING]" : ""}';
      await trayManager.setToolTip('Batterie: $summary');
      await _setupTrayIcon(isRinging);
      await _updateContextMenu(batterySummary: summary);
    } catch (e) {
      debugPrint('Error updating tray: $e');
    }
  }

  Future<void> bringToFront() async {
    try {
      final isMinimized = await windowManager.isMinimized();
      if (isMinimized) {
        await windowManager.restore();
      }
      final isVisible = await windowManager.isVisible();
      if (!isVisible) {
        await windowManager.show();
      }
      await windowManager.focus();
    } catch (e) {
      debugPrint('Error bringing window to front: $e');
    }
  }

  Future<void> minimizeToTray() async {
    try {
      await windowManager.hide();
    } catch (e) {
      debugPrint('Error hiding window: $e');
    }
  }

  // TrayListener callbacks
  @override
  void onTrayIconMouseDown() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await minimizeToTray();
      } else {
        await bringToFront();
        _onShow?.call();
      }
    } catch (_) {
      bringToFront();
      _onShow?.call();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_app':
        bringToFront();
        _onShow?.call();
        break;
      case 'hide_app':
        minimizeToTray();
        break;
      case 'test_alarm':
        _onTest?.call();
        break;
      case 'quit_app':
        quit();
        break;
    }
  }

  // WindowListener callbacks
  @override
  void onWindowClose() async {
    // Intercept window close: hide to tray instead of exiting
    await minimizeToTray();
  }

  Future<void> quit() async {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    _onQuit?.call();
    await windowManager.destroy();
    exit(0);
  }

  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }
}
