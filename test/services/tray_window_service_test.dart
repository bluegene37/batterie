import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/models/battery_info.dart';
import 'package:batterie/services/tray_window_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> windowCalls;
  late List<MethodCall> trayCalls;

  setUp(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    windowCalls = [];
    trayCalls = [];
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (call) async {
      windowCalls.add(call);
      switch (call.method) {
        case 'getBounds':
          return {'x': 0.0, 'y': 0.0, 'width': 380.0, 'height': 710.0};
        case 'getSize':
          return {'width': 380.0, 'height': 710.0};
        case 'getPosition':
          return {'x': 0.0, 'y': 0.0};
        case 'isMinimized':
        case 'isVisible':
        case 'isPreventClose':
        case 'isFocused':
        case 'isFullScreen':
        case 'isMaximized':
          return false;
        default:
          return true;
      }
    });
    messenger.setMockMethodCallHandler(const MethodChannel('tray_manager'), (call) async {
      trayCalls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.leanflutter.plugins/screen_retriever'),
      (call) async {
        final displayMap = {
          'id': '0',
          'name': 'Built-in Retina Display',
          'size': {'width': 1920.0, 'height': 1080.0},
          'visiblePosition': {'dx': 0.0, 'dy': 0.0},
          'visibleSize': {'width': 1920.0, 'height': 1055.0},
          'scaleFactor': 2.0,
        };
        if (call.method == 'getCursorScreenPoint') {
          return {'dx': 0.0, 'dy': 0.0};
        }
        if (call.method == 'getAllDisplays') {
          return {
            'displays': [displayMap],
          };
        }
        return displayMap;
      },
    );
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), null);
    messenger.setMockMethodCallHandler(const MethodChannel('tray_manager'), null);
    messenger.setMockMethodCallHandler(const MethodChannel('dev.leanflutter.plugins/screen_retriever'), null);
  });

  MethodCall? findCall(List<MethodCall> calls, String method) {
    for (final c in calls) {
      if (c.method == method) return c;
    }
    return null;
  }

  group('TrayWindowService alarm mode', () {
    test('enterAlarmMode shows the window on top of everything and flags the tray', () async {
      final service = TrayWindowService();
      const info = BatteryInfo(percentage: 12, isCharging: false, source: PowerSource.battery);

      await service.enterAlarmMode(info);

      expect(findCall(windowCalls, 'show'), isNotNull);
      final onTop = findCall(windowCalls, 'setAlwaysOnTop');
      expect(onTop?.arguments['isAlwaysOnTop'], isTrue);
      final spaces = findCall(windowCalls, 'setVisibleOnAllWorkspaces');
      expect(spaces?.arguments['visible'], isTrue);
      expect(spaces?.arguments['visibleOnFullScreen'], isTrue);
      expect(findCall(windowCalls, 'setBadgeLabel')?.arguments['label'], equals('!'));
      expect(findCall(trayCalls, 'setTitle')?.arguments['title'], equals('⚠ 12%'));
    });

    test('exitAlarmMode restores a normal window and clears the tray flags', () async {
      final service = TrayWindowService();
      await service.exitAlarmMode();

      expect(findCall(windowCalls, 'setAlwaysOnTop')?.arguments['isAlwaysOnTop'], isFalse);
      expect(findCall(windowCalls, 'setVisibleOnAllWorkspaces')?.arguments['visible'], isFalse);
      expect(findCall(windowCalls, 'setBadgeLabel')?.arguments['label'], equals(''));
      expect(findCall(trayCalls, 'setTitle')?.arguments['title'], equals(''));
    });

    test('Unsupported platform calls do not stop the rest of alarm mode', () async {
      // Windows has no "all workspaces", Dock badge, or tray title support.
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (call) async {
        windowCalls.add(call);
        if (call.method == 'setVisibleOnAllWorkspaces' || call.method == 'setBadgeLabel') {
          throw MissingPluginException(call.method);
        }
        return false;
      });
      messenger.setMockMethodCallHandler(const MethodChannel('tray_manager'), (call) async {
        trayCalls.add(call);
        throw MissingPluginException(call.method);
      });

      final service = TrayWindowService();
      const info = BatteryInfo(percentage: 12, isCharging: false, source: PowerSource.battery);

      await service.enterAlarmMode(info);
      expect(findCall(windowCalls, 'setAlwaysOnTop')?.arguments['isAlwaysOnTop'], isTrue);
      expect(findCall(windowCalls, 'show'), isNotNull);

      windowCalls.clear();
      await service.exitAlarmMode();
      expect(findCall(windowCalls, 'setAlwaysOnTop')?.arguments['isAlwaysOnTop'], isFalse);
    });

    test('alarmModeTitle reflects the live percentage', () {
      expect(TrayWindowService.alarmModeTitle(7), equals('⚠ 7%'));
    });

    test('updateContentHeight fixes width, height, and disables resizability', () async {
      final service = TrayWindowService();
      await service.init(
        onShow: () {},
        onTest: () {},
        onQuit: () {},
      );

      windowCalls.clear();
      await service.updateContentHeight(680.0);

      final minSize = findCall(windowCalls, 'setMinimumSize');
      expect(minSize?.arguments['width'], equals(380.0));
      expect(minSize?.arguments['height'], equals(680.0));

      final maxSize = findCall(windowCalls, 'setMaximumSize');
      expect(maxSize?.arguments['width'], equals(380.0));
      expect(maxSize?.arguments['height'], equals(680.0));

      final bounds = findCall(windowCalls, 'setBounds');
      expect(bounds?.arguments['width'], equals(380.0));
      expect(bounds?.arguments['height'], equals(680.0));

      final resizable = findCall(windowCalls, 'setResizable');
      expect(resizable?.arguments['isResizable'], isFalse);
    });
  });
}
