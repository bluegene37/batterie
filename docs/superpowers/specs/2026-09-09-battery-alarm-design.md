# Battery Alarm Desktop Application Specification (macOS & Windows)

## 1. Overview
A fast, lightweight, and reliable Flutter desktop application for macOS and Windows that monitors system battery levels in real-time and sounds an unmissable, continuous loud alarm when user-configured battery thresholds are reached while discharging.

## 2. Core Requirements
- **Platforms**: macOS and Windows (Desktop).
- **Battery Monitoring**: Accurate real-time battery percentage and AC power state detection with efficient polling intervals.
- **Custom Multiple Thresholds**: Ability to define, enable/disable, and edit multiple low battery percentage thresholds (e.g. 20% Warning, 10% Critical).
- **Loud Alarm Playback**: Continuous looping sound with volume control, bundled urgent alarm sound presets, and custom audio file selection (.mp3 / .wav).
- **Alarm Actions**:
  - Auto-silences immediately upon plugging in AC charger.
  - Snooze capability (temporary silence for 2, 5, or 10 minutes).
  - Dismiss button (silences until next threshold is crossed).
  - Test Alarm button for immediate audio loudness verification.
- **Background & Tray Operation**:
  - Runs in macOS menu bar / Windows system tray.
  - Close-to-tray and minimize-to-tray behavior.
  - Automatically un-minimizes and brings window to front with urgent visual banner when an alarm triggers.
- **Efficiency**: Minimal CPU and memory usage, adaptive polling (fast when discharging, backoff when connected to AC).

## 3. Architecture & Components

```
lib/
├── main.dart                      # App entry point, desktop window & tray init
├── models/
│   ├── battery_info.dart          # Battery level %, charging status, power source
│   ├── threshold_rule.dart        # Threshold %, enabled flag, label, custom sound
│   └── alarm_state.dart           # Idle, ringing, snoozed state
├── services/
│   ├── battery_service.dart       # Cross-platform battery monitor with OS native fallbacks
│   ├── alarm_service.dart         # Audio loop playback, volume control, sound assets
│   ├── tray_window_service.dart   # System tray icon, context menu, window focus
│   └── settings_service.dart      # Local preferences persistence
├── controllers/
│   └── battery_alarm_controller.dart # Main controller coordinating state & triggers
└── ui/
    ├── dashboard_screen.dart      # Main desktop dashboard screen
    ├── widgets/
    │   ├── battery_gauge.dart     # Real-time battery indicator
    │   ├── active_alarm_banner.dart # Urgent ringing banner with Snooze / Dismiss
    │   ├── threshold_list.dart    # Add/edit/delete threshold triggers
    │   └── audio_settings_card.dart # Sound picker, volume slider, test button
```

### 3.1. Battery Monitoring Service
- **Source**: `battery_plus` package with native shell command fallback:
  - macOS: `pmset -g batt`
  - Windows: PowerShell `Get-CimInstance -ClassName Win32_Battery`
- **Polling Strategy**:
  - Discharging (battery power): Check every 5 seconds.
  - Charging (AC power): Check every 30 seconds to conserve system resources.
- **Hysteresis**:
  - Triggers on discharge crossing $\le$ threshold.
  - Anti-flapping: Does not re-trigger the exact same threshold once dismissed unless battery level increases above threshold and discharges back down, or snooze expires.

### 3.2. Alarm & Audio Service
- **Engine**: `audioplayers` with low-latency initialization.
- **Sounds**:
  - Preset 1: Urgent Siren (fast oscillating loud siren).
  - Preset 2: Digital Alarm (high-frequency repeating beeps).
  - Preset 3: Urgent Bell (repetitive sharp warning tone).
  - Custom file: Support loading external `.mp3` / `.wav` file.
- **Volume**: Dedicated in-app volume multiplier (0.0 to 1.0).
- **Auto-Silence**: Disarms the audio player immediately when `battery_info.isCharging` or AC power is detected.

### 3.3. Tray & Window Management
- **Tray**:
  - Shows dynamic tooltip and battery icon.
  - Menu: Show App, Test Alarm, Mute/Snooze, Quit.
- **Window**:
  - Close button minimizes to system tray.
  - On alarm trigger: Calls `window_manager.show()`, `window_manager.focus()`, and requests attention.

## 4. Error Handling & Edge Cases
- **No Battery Detected** (e.g. desktop Mac Mini / Desktop PC without battery): Shows clear informational message "No battery detected (Desktop running on AC Power)".
- **Audio Output Unavailable**: Fallback to system desktop notification and visual flashing alert.
- **Corrupted Settings**: Gracefully falls back to default thresholds (20% and 10%).

## 5. Verification Plan
1. **Unit Tests**:
   - Threshold evaluation logic (discharging vs charging, crossing thresholds, hysteresis).
   - Serialization and deserialization of threshold rules and settings.
2. **Integration / Manual Desktop Tests**:
   - Verify battery reading matches macOS battery menu bar.
   - Verify audio plays loudly in loop on macOS and can be silenced via Dismiss, Snooze, and AC charger plug-in.
   - Verify "Close to Tray" keeps process running in menu bar.
   - Verify test sound button functions with adjustable volume.
