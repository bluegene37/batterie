// Gene - Oct 24, 2026: Model representing available application update details and update status for macOS and Windows.

enum UpdateStatus {
  idle,
  checking,
  available,
  upToDate,
  downloading,
  installing,
  error,
}

class UpdateInfo {
  final String version;
  final String tagName;
  final String? releaseNotes;
  final String releaseUrl;
  final String assetUrl;
  final String assetName;
  final int? assetSize;
  final DateTime? publishedAt;
  final bool isStoreBuild;

  const UpdateInfo({
    required this.version,
    required this.tagName,
    this.releaseNotes,
    required this.releaseUrl,
    required this.assetUrl,
    required this.assetName,
    this.assetSize,
    this.publishedAt,
    this.isStoreBuild = false,
  });

  /// Factory constructor to parse GitHub Release API JSON response.
  factory UpdateInfo.fromGitHubRelease({
    required Map<String, dynamic> json,
    required bool isMacOS,
    required bool isWindows,
    bool isStoreBuild = false,
  }) {
    final tagName = (json['tag_name'] as String? ?? '').trim();
    // Strip leading 'v' or 'V' from version string (e.g. 'v1.0.4' -> '1.0.4')
    final version = tagName.startsWith(RegExp(r'^[vV]'))
        ? tagName.substring(1)
        : tagName;

    final releaseUrl = json['html_url'] as String? ?? '';
    final releaseNotes = json['body'] as String?;
    final publishedStr = json['published_at'] as String?;
    final publishedAt =
        publishedStr != null ? DateTime.tryParse(publishedStr) : null;

    final assetsList = json['assets'] as List<dynamic>? ?? [];
    String assetUrl = '';
    String assetName = '';
    int? assetSize;

    if (isMacOS) {
      // For macOS, prefer the .zip bundle for smooth in-place replacement, fallback to .dmg
      dynamic chosenAsset;
      for (final asset in assetsList) {
        if (asset is Map<String, dynamic>) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.endsWith('.zip') && name.contains('macos')) {
            chosenAsset = asset;
            break;
          }
        }
      }
      if (chosenAsset == null) {
        for (final asset in assetsList) {
          if (asset is Map<String, dynamic>) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.dmg')) {
              chosenAsset = asset;
              break;
            }
          }
        }
      }

      if (chosenAsset is Map<String, dynamic>) {
        assetUrl = chosenAsset['browser_download_url'] as String? ?? '';
        assetName = chosenAsset['name'] as String? ?? '';
        assetSize = chosenAsset['size'] as int?;
      }
    } else if (isWindows) {
      // For Windows, find batterie-windows-x64.zip
      dynamic chosenAsset;
      for (final asset in assetsList) {
        if (asset is Map<String, dynamic>) {
          final name = (asset['name'] as String? ?? '').toLowerCase();
          if (name.endsWith('.zip') &&
              (name.contains('windows') || name.contains('win'))) {
            chosenAsset = asset;
            break;
          }
        }
      }
      if (chosenAsset is Map<String, dynamic>) {
        assetUrl = chosenAsset['browser_download_url'] as String? ?? '';
        assetName = chosenAsset['name'] as String? ?? '';
        assetSize = chosenAsset['size'] as int?;
      }
    }

    return UpdateInfo(
      version: version,
      tagName: tagName,
      releaseNotes: releaseNotes,
      releaseUrl: releaseUrl,
      assetUrl: assetUrl,
      assetName: assetName,
      assetSize: assetSize,
      publishedAt: publishedAt,
      isStoreBuild: isStoreBuild,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateInfo &&
        other.version == version &&
        other.tagName == tagName &&
        other.assetUrl == assetUrl &&
        other.isStoreBuild == isStoreBuild;
  }

  @override
  int get hashCode => Object.hash(version, tagName, assetUrl, isStoreBuild);
}
