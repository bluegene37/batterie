import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../models/battery_info.dart';

class TrayWindowService with TrayListener, WindowListener {
  VoidCallback? _onShow;
  VoidCallback? _onTest;
  VoidCallback? _onQuit;
  VoidCallback? _onToggleTheme;
  bool _isInitialized = false;

  Future<void> init({
    required VoidCallback onShow,
    required VoidCallback onTest,
    required VoidCallback onQuit,
    VoidCallback? onToggleTheme,
  }) async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return;
    }

    _onShow = onShow;
    _onTest = onTest;
    _onQuit = onQuit;
    _onToggleTheme = onToggleTheme;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      final windowOptions = WindowOptions(
        size: const Size(380, 710),
        minimumSize: const Size(380, 710),
        maximumSize: const Size(380, 710),
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
        await windowManager.setResizable(false);
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
        MenuItem(
          key: 'toggle_theme',
          label: 'Toggle Dark / Light Theme',
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
    // Keep the menu bar readout current while the alarm is ringing
    // (macOS only; ignored elsewhere).
    await _attempt('tray title',
        () => trayManager.setTitle(isRinging ? alarmModeTitle(info.percentage) : ''));
  }

  /// Text shown next to the tray icon while an alarm is ringing.
  static String alarmModeTitle(int percentage) => '⚠ $percentage%';

  /// Alarm takeover: surface the window above every other window and Space,
  /// and flag the menu bar and Dock so the alarm is visible from anywhere.
  ///
  /// Each step is attempted on its own: "all Spaces", the Dock badge, and the
  /// tray title only exist on macOS, and an unsupported call must not stop
  /// the always-on-top window from appearing on Windows or Linux.
  Future<void> enterAlarmMode(BatteryInfo info) async {
    await _attempt('visible on all Spaces',
        () => windowManager.setVisibleOnAllWorkspaces(true, visibleOnFullScreen: true));
    await _attempt('always on top', () => windowManager.setAlwaysOnTop(true));
    await bringToFront();
    await _attempt('dock badge', () => windowManager.setBadgeLabel('!'));
    await _attempt('tray title',
        () => trayManager.setTitle(alarmModeTitle(info.percentage)));
  }

  /// Undo [enterAlarmMode]: back to a normal window, no badge, no tray text.
  Future<void> exitAlarmMode() async {
    await _attempt('always on top', () => windowManager.setAlwaysOnTop(false));
    await _attempt('visible on all Spaces',
        () => windowManager.setVisibleOnAllWorkspaces(false));
    await _attempt('dock badge', () => windowManager.setBadgeLabel(''));
    await _attempt('tray title', () => trayManager.setTitle(''));
  }

  Future<void> _attempt(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Alarm mode: $what unavailable on this platform: $e');
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

  double? _lastFixedHeight;

  /// Dynamically fixes the window width and height to fit the widgets,
  /// preventing enlarging or resizing by the user.
  Future<void> updateContentHeight(double contentHeight) async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return;
    }
    if (!_isInitialized) return;

    final targetHeight = contentHeight.ceilToDouble();
    if (_lastFixedHeight != null && (targetHeight - _lastFixedHeight!).abs() < 2.0) {
      return;
    }
    _lastFixedHeight = targetHeight;

    try {
      const fixedWidth = 380.0;
      final fixedSize = Size(fixedWidth, targetHeight);
      await windowManager.setMinimumSize(fixedSize);
      await windowManager.setMaximumSize(fixedSize);
      await windowManager.setSize(fixedSize);
      await windowManager.setResizable(false);
    } catch (e) {
      debugPrint('Error updating window fixed size: $e');
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
      case 'toggle_theme':
        _onToggleTheme?.call();
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
