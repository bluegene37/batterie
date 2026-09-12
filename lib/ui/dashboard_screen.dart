import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../controllers/battery_alarm_controller.dart';
import '../services/tray_window_service.dart';
import '../theme/app_theme.dart';
import 'widgets/active_alarm_banner.dart';
import 'widgets/alarm_takeover.dart';
import 'widgets/audio_settings_card.dart';
import 'widgets/battery_gauge.dart';
import 'widgets/threshold_list.dart';

class DashboardScreen extends StatefulWidget {
  final BatteryAlarmController controller;
  final VoidCallback onMinimizeToTray;
  final TrayWindowService? trayService;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onMinimizeToTray,
    this.trayService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndExpandWindow());
  }

  void _measureAndExpandWindow() {
    if (!mounted || widget.trayService == null) return;
    final context = _contentKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final isMacOS = AppTheme.isMacOS;
    final appBarHeight = isMacOS ? 40.0 : 46.0;
    // vertical padding (16.0) + breathing room (14.0)
    final totalHeight = renderBox.size.height + appBarHeight + 30.0;
    widget.trayService?.updateContentHeight(totalHeight);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndExpandWindow());

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isMacOS = AppTheme.isMacOS;
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: isMacOS ? 40 : 46,
            titleSpacing: isMacOS ? 78 : 12,
            flexibleSpace: isMacOS
                ? const DragToMoveArea(child: SizedBox.expand())
                : null,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    width: 22,
                    height: 22,
                    semanticLabel: 'Batterie logo',
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.battery_charging_full_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Battery Alarm Monitor',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                tooltip: isDark
                    ? 'Switch to light mode (Paper & Ink)'
                    : 'Switch to dark mode (Dark Roast)',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 17,
                ),
                onPressed: () {
                  widget.controller.toggleThemeMode(currentBrightness: theme.brightness);
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 16,
                tooltip: 'Minimize to Menu Bar / Tray',
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                onPressed: widget.onMinimizeToTray,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: widget.controller.alarmState.isRinging
              ? AlarmTakeover(
                  alarmState: widget.controller.alarmState,
                  batteryInfo: widget.controller.batteryInfo,
                  snoozeMinutes: widget.controller.snoozeMinutes,
                  onSnooze: () => widget.controller.snooze(),
                  onDismiss: () => widget.controller.dismiss(),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      key: _contentKey,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ActiveAlarmBanner(
                          alarmState: widget.controller.alarmState,
                          batteryInfo: widget.controller.batteryInfo,
                          snoozeMinutes: widget.controller.snoozeMinutes,
                          onSnooze: () => widget.controller.snooze(),
                          onDismiss: () => widget.controller.dismiss(),
                        ),
                        BatteryGauge(info: widget.controller.batteryInfo),
                        const SizedBox(height: 10),
                        ThresholdList(
                          rules: widget.controller.thresholdRules,
                          defaultSound: widget.controller.defaultSound,
                          defaultCustomSoundPath: widget.controller.customSoundPath,
                          onAdd: (percentage, label, sound, customPath) =>
                              widget.controller.addThreshold(
                            percentage,
                            label,
                            soundType: sound,
                            customSoundPath: customPath,
                          ),
                          onUpdate: widget.controller.updateThreshold,
                          onDelete: widget.controller.removeThreshold,
                          onPreview: (sound, customPath) => widget.controller.previewSound(
                            soundType: sound,
                            customPath: customPath,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AudioSettingsCard(
                          selectedSound: widget.controller.defaultSound,
                          customSoundPath: widget.controller.customSoundPath,
                          volume: widget.controller.volume,
                          snoozeMinutes: widget.controller.snoozeMinutes,
                          isTesting: widget.controller.isTesting,
                          onSoundChanged: widget.controller.setDefaultSound,
                          onCustomPathChanged: widget.controller.setCustomSoundPath,
                          onVolumeChanged: widget.controller.setVolume,
                          onSnoozeChanged: widget.controller.setSnoozeMinutes,
                          onTestAlarm: widget.controller.testAlarm,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                Icons.coffee_rounded,
                                size: 13,
                                color: theme.colorScheme.primary.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Lives in menu bar • Closing window keeps monitoring active',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
