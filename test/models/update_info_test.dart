// Gene - Oct 24, 2026: Tests for UpdateInfo model parsing, asset resolution, and equality.

import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/models/update_info.dart';

void main() {
  group('UpdateInfo tests', () {
    final mockReleaseJson = {
      'tag_name': 'v1.0.4',
      'html_url': 'https://github.com/bluegene37/batterie/releases/tag/v1.0.4',
      'body': '## Release Notes\n- New auto-update feature',
      'published_at': '2026-10-24T12:00:00Z',
      'assets': [
        {
          'name': 'batterie-macos.zip',
          'browser_download_url': 'https://github.com/releases/download/v1.0.4/batterie-macos.zip',
          'size': 19000000,
        },
        {
          'name': 'batterie-macos.dmg',
          'browser_download_url': 'https://github.com/releases/download/v1.0.4/batterie-macos.dmg',
          'size': 20000000,
        },
        {
          'name': 'batterie-windows-x64.zip',
          'browser_download_url': 'https://github.com/releases/download/v1.0.4/batterie-windows-x64.zip',
          'size': 14000000,
        },
      ],
    };

    test('parses macOS release preferring .zip asset', () {
      final info = UpdateInfo.fromGitHubRelease(
        json: mockReleaseJson,
        isMacOS: true,
        isWindows: false,
      );

      expect(info.version, equals('1.0.4'));
      expect(info.tagName, equals('v1.0.4'));
      expect(info.releaseNotes, contains('New auto-update feature'));
      expect(info.assetName, equals('batterie-macos.zip'));
      expect(info.assetUrl, contains('batterie-macos.zip'));
      expect(info.assetSize, equals(19000000));
      expect(info.isStoreBuild, isFalse);
    });

    test('parses macOS release falling back to .dmg if .zip not found', () {
      final dmgOnlyJson = {
        'tag_name': 'v1.0.4',
        'html_url': 'https://github.com/bluegene37/batterie/releases/tag/v1.0.4',
        'assets': [
          {
            'name': 'batterie-macos.dmg',
            'browser_download_url': 'https://github.com/releases/download/v1.0.4/batterie-macos.dmg',
            'size': 20000000,
          },
        ],
      };

      final info = UpdateInfo.fromGitHubRelease(
        json: dmgOnlyJson,
        isMacOS: true,
        isWindows: false,
      );

      expect(info.assetName, equals('batterie-macos.dmg'));
      expect(info.assetUrl, contains('batterie-macos.dmg'));
    });

    test('parses Windows release asset correctly', () {
      final info = UpdateInfo.fromGitHubRelease(
        json: mockReleaseJson,
        isMacOS: false,
        isWindows: true,
        isStoreBuild: false,
      );

      expect(info.version, equals('1.0.4'));
      expect(info.assetName, equals('batterie-windows-x64.zip'));
      expect(info.assetUrl, contains('batterie-windows-x64.zip'));
      expect(info.isStoreBuild, isFalse);
    });

    test('preserves isStoreBuild flag', () {
      final info = UpdateInfo.fromGitHubRelease(
        json: mockReleaseJson,
        isMacOS: false,
        isWindows: true,
        isStoreBuild: true,
      );

      expect(info.isStoreBuild, isTrue);
    });

    test('equality and hashCode match identical UpdateInfo', () {
      final info1 = UpdateInfo(
        version: '1.0.4',
        tagName: 'v1.0.4',
        releaseUrl: 'https://example.com',
        assetUrl: 'https://example.com/asset.zip',
        assetName: 'asset.zip',
      );
      final info2 = UpdateInfo(
        version: '1.0.4',
        tagName: 'v1.0.4',
        releaseUrl: 'https://example.com',
        assetUrl: 'https://example.com/asset.zip',
        assetName: 'asset.zip',
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
    });
  });
}
