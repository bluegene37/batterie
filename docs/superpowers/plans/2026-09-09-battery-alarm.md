# Battery Alarm Desktop Application Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a fast, lightweight, and reliable Flutter desktop app for macOS and Windows that sounds an unmissable, continuous loud alarm when battery reaches user-set percentage thresholds while discharging.

**Architecture:** Service-oriented architecture with dedicated services for battery monitoring (with OS native shell fallbacks), low-latency audio alarm looping, local preferences persistence, and system tray / desktop window management. A central reactive controller evaluates thresholds with hysteresis, anti-flapping, and automatic plug-in disarm.

**Tech Stack:** Flutter Desktop (macOS & Windows), `audioplayers`, `battery_plus`, `tray_manager`, `window_manager`, `shared_preferences`, `file_picker`, Material 3.

**Spec:** [docs/superpowers/specs/2026-09-09-battery-alarm-design.md](file:///Users/bluegene37/Documents/personal_projects/Codes/batterie/docs/superpowers/specs/2026-09-09-battery-alarm-design.md)

## Global Constraints
- Target platforms: macOS (ARM64 & x86_64) and Windows (Desktop).
- Flutter SDK: 3.47.2+, Dart 3.13.2+.
- Audio: Must support continuous loud alarm looping until silenced or plugged into charger.
- Battery detection: Zero lag, resilient against plugin hiccups via native `pmset` (macOS) and WMI/CIM (Windows) fallbacks.
- Efficiency: Adaptive polling (<0.1% CPU), memory-efficient asset loading.

---

### Task 1: Flutter Project Setup & Desktop Dependencies

**Files:**
- Create: `pubspec.yaml`, `macos/`, `windows/` (via `flutter create --platforms=macos,windows .`)
- Modify: `pubspec.yaml`
- Assets: `assets/sounds/siren.wav`, `assets/sounds/digital_alarm.wav`, `assets/sounds/bell.wav`, `assets/icons/tray_icon.png`

**Interfaces:**
- Consumes: None (root scaffolding)
- Produces: Base Flutter desktop application with configured macOS/Windows targets, assets, and dependencies.

- [ ] **Step 1: Scaffold Flutter desktop project**
Run:
```bash
flutter create --platforms=macos,windows --org com.batterie app .
```

- [ ] **Step 2: Add required dependencies to `pubspec.yaml`**
Add:
```yaml
dependencies:
  flutter:
    sdk: flutter
  battery_plus: ^6.2.1
  audioplayers: ^6.1.0
  window_manager: ^0.4.3
  tray_manager: ^0.2.4
  shared_preferences: ^2.3.2
  file_picker: ^8.1.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

- [ ] **Step 3: Generate high-clarity bundled alarm audio files and tray icon**
Generate synthesized loud wave audio files (`assets/sounds/siren.wav`, `assets/sounds/digital_alarm.wav`, `assets/sounds/bell.wav`) using a Dart/Python script producing crisp PCM audio wave headers with loud square/sawtooth tones.

- [ ] **Step 4: Update `pubspec.yaml` assets section and run `flutter pub get`**
Ensure assets are registered:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
    - assets/icons/
```
Run: `flutter pub get`
Expected: Resolution succeeded without version conflicts.

- [ ] **Step 5: Commit**
```bash
git add .
git commit -m "chore: scaffold flutter desktop project with audio and desktop dependencies"
```

---

### Task 2: Domain Models & Unit Tests

**Files:**
- Create: `lib/models/battery_info.dart`
- Create: `lib/models/threshold_rule.dart`
- Create: `lib/models/alarm_state.dart`
- Test: `test/models/models_test.dart`

**Interfaces:**
- Consumes: None
- Produces:
  - `class BatteryInfo`: `int percentage`, `bool isCharging`, `String statusDescription`
  - `class ThresholdRule`: `String id`, `int percentage`, `String label`, `bool isEnabled`, `String soundType`, `String? customSoundPath`, `toJson()`, `fromJson()`
  - `class AlarmState`: `AlarmStatus status` (`idle`, `ringing`, `snoozed`), `ThresholdRule? triggeredRule`, `DateTime? snoozeUntil`

- [ ] **Step 1: Write failing model unit tests**
Create `test/models/models_test.dart` with tests for:
- `ThresholdRule` serialization/deserialization to JSON.
- `BatteryInfo` factory helpers and status string formatting.
- `AlarmState` snooze calculation and copyWith.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/models/models_test.dart`
Expected: FAIL with compilation error (classes not found).

- [ ] **Step 3: Implement `BatteryInfo`, `ThresholdRule`, and `AlarmState`**
Create the models in `lib/models/`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/models/models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/models test/models
git commit -m "feat: implement battery, threshold, and alarm domain models"
```

---

### Task 3: Cross-Platform Battery Monitoring Service

**Files:**
- Create: `lib/services/battery_service.dart`
- Test: `test/services/battery_service_test.dart`

**Interfaces:**
- Consumes: `BatteryInfo`, `battery_plus`, `dart:io` Process execution
- Produces:
  - `abstract class BatteryService` / `class SystemBatteryService`:
    - `Future<BatteryInfo> getBatteryInfo()`
    - `Stream<BatteryInfo> watchBatteryInfo({Duration? interval})`
    - `void dispose()`

- [ ] **Step 1: Write failing battery service unit test with mocked command output**
Test parsing macOS `pmset -g batt` output:
`"Now drawing from 'Battery Power'\n -InternalBattery-0 (id=123) 18%; discharging; 1:20 remaining"`
Should parse to `percentage = 18`, `isCharging = false`.
Test parsing AC power output:
`"Now drawing from 'AC Power'\n -InternalBattery-0 (id=123) 85%; charging; 0:45 remaining"`
Should parse to `percentage = 85`, `isCharging = true`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/services/battery_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `BatteryService` with `pmset` and `battery_plus` fallback**
Write `lib/services/battery_service.dart`:
- Uses `pmset -g batt` on macOS for zero-dependency exact readings.
- Uses `battery_plus` as standard multi-platform reader.
- Polling stream adjusts interval (5 seconds on battery, 30 seconds on AC).

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/services/battery_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/services/battery_service.dart test/services/battery_service_test.dart
git commit -m "feat: implement robust cross-platform battery monitoring service"
```

---

### Task 4: Audio Alarm Engine

**Files:**
- Create: `lib/services/alarm_service.dart`
- Test: `test/services/alarm_service_test.dart`

**Interfaces:**
- Consumes: `audioplayers`, `ThresholdRule`
- Produces:
  - `class AlarmService`:
    - `Future<void> init()`
    - `Future<void> startAlarm({required String soundType, String? customPath, double volume})`
    - `Future<void> testAlarm({required String soundType, String? customPath, double volume, Duration duration})`
    - `Future<void> stopAlarm()`
    - `void setVolume(double volume)`
    - `bool get isRinging`

- [ ] **Step 1: Write unit test for alarm sound path resolution and state**
Create `test/services/alarm_service_test.dart` testing mapping of preset names (`siren`, `digital`, `bell`) to asset paths, volume clamping (0.0 to 1.0), and active state flags.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/services/alarm_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `AlarmService`**
Write `lib/services/alarm_service.dart` with `AudioPlayer`, looping mode, volume management, and test playback.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/services/alarm_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/services/alarm_service.dart test/services/alarm_service_test.dart
git commit -m "feat: implement audio alarm engine with presets and looping"
```

---

### Task 5: Settings Persistence Service

**Files:**
- Create: `lib/services/settings_service.dart`
- Test: `test/services/settings_service_test.dart`

**Interfaces:**
- Consumes: `shared_preferences`, `ThresholdRule`
- Produces:
  - `class SettingsService`:
    - `Future<List<ThresholdRule>> loadThresholds()`
    - `Future<void> saveThresholds(List<ThresholdRule> rules)`
    - `Future<double> loadVolume()`
    - `Future<void> saveVolume(double volume)`
    - `Future<String> loadDefaultSound()`
    - `Future<void> saveDefaultSound(String sound)`
    - `Future<int> loadSnoozeMinutes()`
    - `Future<void> saveSnoozeMinutes(int minutes)`

- [ ] **Step 1: Write failing settings service unit tests**
Create `test/services/settings_service_test.dart` with `SharedPreferences.setMockInitialValues({})`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/services/settings_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `SettingsService`**
Write `lib/services/settings_service.dart` with defaults:
- Warning threshold: 20%
- Critical threshold: 10%
- Volume: 1.0 (100%)
- Sound: `siren`
- Snooze: 5 minutes

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/services/settings_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/services/settings_service.dart test/services/settings_service_test.dart
git commit -m "feat: implement settings service for rules and audio config"
```

---

### Task 6: Battery Alarm Controller (Logic, Hysteresis, Auto-Disarm)

**Files:**
- Create: `lib/controllers/battery_alarm_controller.dart`
- Test: `test/controllers/battery_alarm_controller_test.dart`

**Interfaces:**
- Consumes: `BatteryService`, `AlarmService`, `SettingsService`, `BatteryInfo`, `ThresholdRule`, `AlarmState`
- Produces:
  - `class BatteryAlarmController extends ChangeNotifier`:
    - `BatteryInfo get batteryInfo`
    - `AlarmState get alarmState`
    - `List<ThresholdRule> get thresholdRules`
    - `double get volume`
    - `String get defaultSound`
    - `int get snoozeMinutes`
    - `void evaluateBattery(BatteryInfo info)`
    - `void snooze()`
    - `void dismiss()`
    - `void testAlarm()`
    - `void addThreshold(int percentage, String label)`
    - `void updateThreshold(ThresholdRule rule)`
    - `void removeThreshold(String id)`
    - `void setVolume(double volume)`
    - `void setDefaultSound(String sound)`

- [ ] **Step 1: Write comprehensive controller unit tests**
Tests verifying:
- Crossing threshold while discharging triggers alarm.
- Charging state immediately stops ringing alarm.
- Snooze silences alarm until snooze time expires.
- Dismiss prevents re-triggering for same threshold level.
- Multi-threshold behavior: crossing 20% fires, dismissed; then dropping to 10% fires critical alarm.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/controllers/battery_alarm_controller_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `BatteryAlarmController`**
Write `lib/controllers/battery_alarm_controller.dart` with ChangeNotifier and robust event loop.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/controllers/battery_alarm_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/controllers/battery_alarm_controller.dart test/controllers/battery_alarm_controller_test.dart
git commit -m "feat: implement central battery alarm controller with hysteresis and auto-disarm"
```

---

### Task 7: Desktop Window & System Tray Integration

**Files:**
- Create: `lib/services/tray_window_service.dart`
- Modify: `macos/Runner/MainFlutterWindow.swift`, `lib/main.dart`

**Interfaces:**
- Consumes: `window_manager`, `tray_manager`, `BatteryAlarmController`
- Produces:
  - `class TrayWindowService`:
    - `Future<void> init({required VoidCallback onShow, required VoidCallback onTest, required VoidCallback onQuit})`
    - `Future<void> updateTray(BatteryInfo info, bool isRinging)`
    - `Future<void> bringToFront()`
    - `Future<void> minimizeToTray()`

- [ ] **Step 1: Implement `TrayWindowService`**
Write `lib/services/tray_window_service.dart`:
- Configures tray icon, tooltip with battery status, and context menu.
- Window close interception to minimize to tray instead of quitting.
- `bringToFront()` invokes `windowManager.show()`, `windowManager.focus()`, and `windowManager.setAlwaysOnTop(true)` during active alarm.

- [ ] **Step 2: Wire `TrayWindowService` with `BatteryAlarmController`**
When `alarmState.status == AlarmStatus.ringing`, automatically trigger `bringToFront()`.

- [ ] **Step 3: Commit**
```bash
git add lib/services/tray_window_service.dart
git commit -m "feat: implement desktop tray and window management service"
```

---

### Task 8: Desktop UI Dashboard & Widgets

**Files:**
- Create: `lib/ui/widgets/battery_gauge.dart`
- Create: `lib/ui/widgets/active_alarm_banner.dart`
- Create: `lib/ui/widgets/threshold_list.dart`
- Create: `lib/ui/widgets/audio_settings_card.dart`
- Create: `lib/ui/dashboard_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/ui/dashboard_screen_test.dart`

**Interfaces:**
- Consumes: `BatteryAlarmController`, `Material 3`
- Produces: Clean, modern desktop dashboard UI.

- [ ] **Step 1: Implement `BatteryGauge` widget**
Displays battery percentage with dynamic color gradient (Green > 40%, Orange 21-40%, Red <= 20%), charging bolt badge, and power status text.

- [ ] **Step 2: Implement `ActiveAlarmBanner` widget**
Pulsing loud alarm banner showing:
- "CRITICAL: BATTERY AT X% - PLUG IN CHARGER NOW!"
- "Snooze (5m)" button
- "Dismiss" button
- Only visible when `alarmState.status == AlarmStatus.ringing`.

- [ ] **Step 3: Implement `ThresholdList` widget**
Cards displaying active thresholds with:
- Percentage badge
- Label (e.g., Warning, Critical)
- Switch toggle (on/off)
- Delete icon button
- "Add Threshold" button with dialog slider/input.

- [ ] **Step 4: Implement `AudioSettingsCard` widget**
- Sound preset dropdown (*Urgent Siren*, *Digital Alarm*, *Alert Bell*, *Custom Audio File...*)
- File picker button if custom audio is selected
- Volume slider (0% - 100%)
- "Test Alarm (3s)" button with countdown indicator

- [ ] **Step 5: Assemble `DashboardScreen` and integrate into `lib/main.dart`**
Put components into a desktop layout with dark/light mode Material 3 styling.

- [ ] **Step 6: Write widget test for dashboard screen**
Verify rendering of battery gauge, threshold items, and alarm banner.
Run: `flutter test test/ui/dashboard_screen_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**
```bash
git add lib/ui lib/main.dart test/ui
git commit -m "feat: assemble modern desktop battery alarm dashboard UI"
```

---

### Task 9: System Verification & Release Build Verification

**Files:**
- Entire codebase

- [ ] **Step 1: Static analysis**
Run: `flutter analyze`
Expected: 0 errors, 0 warnings.

- [ ] **Step 2: Complete test suite**
Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 3: Run app on macOS desktop**
Launch: `flutter run -d macos`
Verify:
- Battery % accurately detected from macOS battery manager.
- Sound test plays loud and clear.
- Window close minimizes to tray.
- Alarm sounds when simulated or real threshold is hit.

- [ ] **Step 4: Commit and finalize walkthrough**
```bash
git add .
git commit -m "chore: complete verification and packaging"
```
