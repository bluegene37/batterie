// Gene - Oct 24, 2026: Neumorphic UpdateBanner widget displaying new version alerts, download progress, and restart trigger.

import 'package:flutter/material.dart';
import '../../models/update_info.dart';
import '../../theme/app_theme.dart';

class UpdateBanner extends StatelessWidget {
  final UpdateInfo? updateInfo;
  final UpdateStatus status;
  final double progress;
  final String? errorMessage;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  const UpdateBanner({
    super.key,
    required this.updateInfo,
    required this.status,
    required this.progress,
    this.errorMessage,
    required this.onUpdate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (updateInfo == null && status != UpdateStatus.upToDate && status != UpdateStatus.error) {
      return const SizedBox.shrink();
    }

    if (status == UpdateStatus.idle) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bannerBg = isDark
        ? const Color(0xFF1E2836)
        : const Color(0xFFEBF3FB);
    final borderColor = scheme.primary.withValues(alpha: 0.35);

    return AnimatedContainer(
      duration: AppMotion.standardDuration,
      curve: AppMotion.standardCurve,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.8),
            blurRadius: 6,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : const Color(0xFFA3B1C6).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == UpdateStatus.error
                    ? Icons.error_outline_rounded
                    : (status == UpdateStatus.upToDate
                        ? Icons.check_circle_outline_rounded
                        : Icons.system_update_rounded),
                size: 19,
                color: status == UpdateStatus.error
                    ? scheme.error
                    : scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getTitle(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                splashRadius: 14,
                icon: const Icon(Icons.close_rounded, size: 16),
                tooltip: 'Dismiss',
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getMessage(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          if (status == UpdateStatus.downloading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 0 ? progress : null,
                minHeight: 5,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% completed',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                color: scheme.primary,
              ),
            ),
          ],
          if (status == UpdateStatus.available || status == UpdateStatus.error) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: onUpdate,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  icon: Icon(
                    status == UpdateStatus.error
                        ? Icons.refresh_rounded
                        : Icons.arrow_circle_up_rounded,
                    size: 15,
                  ),
                  label: Text(
                    status == UpdateStatus.error ? 'Retry' : 'Update & Restart',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getTitle() {
    switch (status) {
      case UpdateStatus.checking:
        return 'Checking for updates...';
      case UpdateStatus.available:
        return 'Update Available (v${updateInfo?.version ?? ""})';
      case UpdateStatus.downloading:
        return 'Downloading Update v${updateInfo?.version ?? ""}';
      case UpdateStatus.installing:
        return 'Installing Update...';
      case UpdateStatus.upToDate:
        return 'Batterie is Up to Date';
      case UpdateStatus.error:
        return 'Update Failed';
      case UpdateStatus.idle:
        return '';
    }
  }

  String _getMessage() {
    switch (status) {
      case UpdateStatus.checking:
        return 'Connecting to GitHub Releases...';
      case UpdateStatus.available:
        if (updateInfo?.isStoreBuild ?? false) {
          return 'A new release is available on GitHub. Updates are also published through Microsoft Store.';
        }
        return 'A new version is ready. Click below to install and restart seamlessly.';
      case UpdateStatus.downloading:
        return 'Downloading release package in background...';
      case UpdateStatus.installing:
        return 'Extracting package and preparing restart...';
      case UpdateStatus.upToDate:
        return 'You are on the latest version of Batterie.';
      case UpdateStatus.error:
        return errorMessage ?? 'An error occurred while downloading or installing the update.';
      case UpdateStatus.idle:
        return '';
    }
  }
}
