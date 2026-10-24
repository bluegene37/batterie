// Gene - Oct 24, 2026: Service for checking, downloading, and applying application updates on macOS and Windows.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/update_info.dart';

class UpdateService {
  static const String defaultRepo = 'bluegene37/batterie';
  static const String currentAppVersion = '1.0.3';

  final String repo;
  final String currentVersion;
  final HttpClient? _customHttpClient;

  // Gene - Oct 24, 2026: Suppressed prefer_initializing_formals to retain clear public parameter name customHttpClient. Preserved previous constructor below.
  // UpdateService({
  //   this.repo = defaultRepo,
  //   this.currentVersion = currentAppVersion,
  //   HttpClient? customHttpClient,
  // }) : _customHttpClient = customHttpClient;
  UpdateService({
    this.repo = defaultRepo,
    this.currentVersion = currentAppVersion,
    HttpClient? customHttpClient,
  }) : _customHttpClient = customHttpClient; // ignore: prefer_initializing_formals

  HttpClient _createHttpClient() {
    final client = _customHttpClient ?? HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    return client;
  }

  /// Compares semantic versions (e.g. '1.0.4' vs '1.0.3' -> true).
  static bool isNewerVersion(String current, String candidate) {
    List<int> parse(String v) {
      final clean = v
          .split('+')
          .first
          .split('-')
          .first
          .replaceAll(RegExp(r'[^0-9.]'), '');
      return clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    }

    final cParts = parse(current);
    final rParts = parse(candidate);
    final maxLen = cParts.length > rParts.length ? cParts.length : rParts.length;

    for (int i = 0; i < maxLen; i++) {
      final c = i < cParts.length ? cParts[i] : 0;
      final r = i < rParts.length ? rParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// Detects whether the app is running in a Microsoft Store MSIX container.
  bool get isStoreBuild {
    if (!Platform.isWindows) return false;
    try {
      final exePath = Platform.resolvedExecutable.toLowerCase();
      // MSIX apps run from WindowsApps container
      if (exePath.contains('windowsapps')) return true;
    } catch (_) {}
    return false;
  }

  /// Queries GitHub Releases API for the latest release.
  Future<UpdateInfo?> checkForUpdates() async {
    final client = _createHttpClient();
    try {
      final uri = Uri.parse('https://api.github.com/repos/$repo/releases/latest');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Batterie-App-Updater');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        debugPrint('UpdateService: GitHub returned HTTP ${response.statusCode}');
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> json =
          jsonDecode(responseBody) as Map<String, dynamic>;

      final updateInfo = UpdateInfo.fromGitHubRelease(
        json: json,
        isMacOS: Platform.isMacOS,
        isWindows: Platform.isWindows,
        isStoreBuild: isStoreBuild,
      );

      if (isNewerVersion(currentVersion, updateInfo.version)) {
        return updateInfo;
      }
      return null;
    } catch (e) {
      debugPrint('UpdateService check error: $e');
      return null;
    } finally {
      if (_customHttpClient == null) {
        client.close();
      }
    }
  }

  /// Downloads release asset with progress callback (0.0 to 1.0).
  Future<File> downloadReleaseAsset(
    UpdateInfo updateInfo, {
    void Function(double progress)? onProgress,
  }) async {
    final client = _createHttpClient();
    try {
      final downloadUrl = updateInfo.assetUrl;
      if (downloadUrl.isEmpty) {
        throw Exception('No compatible release asset URL found for this platform.');
      }

      final tempDir = await Directory.systemTemp.createTemp('batterie_update_');
      final fileName = updateInfo.assetName.isNotEmpty
          ? updateInfo.assetName
          : (Platform.isMacOS ? 'batterie-macos.zip' : 'batterie-windows-x64.zip');
      final targetFile = File('${tempDir.path}/$fileName');

      final uri = Uri.parse(downloadUrl);
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'Batterie-App-Updater');

      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Download failed with HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength > 0
          ? response.contentLength
          : (updateInfo.assetSize ?? -1);

      int receivedBytes = 0;
      final sink = targetFile.openWrite();

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0 && onProgress != null) {
          onProgress((receivedBytes / totalBytes).clamp(0.0, 1.0));
        }
      }

      await sink.flush();
      await sink.close();
      onProgress?.call(1.0);
      return targetFile;
    } finally {
      if (_customHttpClient == null) {
        client.close();
      }
    }
  }

  /// Installs the downloaded update file and relaunches the app.
  Future<bool> installUpdate(File downloadedFile) async {
    try {
      if (Platform.isMacOS) {
        return await _installMacOsUpdate(downloadedFile);
      } else if (Platform.isWindows) {
        return await _installWindowsUpdate(downloadedFile);
      }
      return false;
    } catch (e) {
      debugPrint('UpdateService install error: $e');
      return false;
    }
  }

  /// macOS: unzips the app bundle and spawns a detached updater script to swap and restart.
  Future<bool> _installMacOsUpdate(File downloadedFile) async {
    final filePath = downloadedFile.path;

    if (filePath.toLowerCase().endsWith('.dmg')) {
      // If asset is DMG, open it for drag-and-drop
      await Process.run('open', [filePath]);
      return true;
    }

    // Must be .zip archive
    final tempDir = downloadedFile.parent;
    final extractDir = Directory('${tempDir.path}/extracted');
    await extractDir.create(recursive: true);

    // Extract zip preserving bundle structure and permissions
    final unzipResult = await Process.run(
      'ditto',
      ['-x', '-k', filePath, extractDir.path],
    );

    if (unzipResult.exitCode != 0) {
      debugPrint('ditto unzip failed: ${unzipResult.stderr}');
      return false;
    }

    // Locate the newly extracted .app bundle
    String? newAppPath;
    final entities = extractDir.listSync(recursive: true);
    for (final entity in entities) {
      if (entity is Directory && entity.path.endsWith('.app')) {
        newAppPath = entity.path;
        break;
      }
    }

    if (newAppPath == null) {
      debugPrint('No .app found in extracted update');
      return false;
    }

    // Determine current running .app bundle path from executable
    // (e.g. /Applications/batterie.app/Contents/MacOS/batterie -> /Applications/batterie.app)
    final exePath = Platform.resolvedExecutable;
    final appIndex = exePath.lastIndexOf('.app');
    if (appIndex == -1) {
      debugPrint('Running binary is not inside a .app bundle (debug run?)');
      return false;
    }
    final targetAppPath = exePath.substring(0, appIndex + 4);

    final pid = pidInstance;
    final scriptPath = '${tempDir.path}/apply_update.sh';
    final scriptFile = File(scriptPath);

    final scriptContent = '''#!/usr/bin/env bash
# Wait for main application process ($pid) to exit
while kill -0 $pid 2>/dev/null; do
  sleep 0.4
done

# Replace current application bundle with updated version
rm -rf "$targetAppPath"
cp -R "$newAppPath" "$targetAppPath"

# Strip quarantine attributes if needed
xattr -cr "$targetAppPath" 2>/dev/null || true

# Relaunch updated application
open -n "$targetAppPath"

# Clean up staging files
rm -rf "${tempDir.path}"
''';

    await scriptFile.writeAsString(scriptContent);
    await Process.run('chmod', ['+x', scriptPath]);

    // Spawn detached updater process
    await Process.start(
      '/bin/bash',
      [scriptPath],
      mode: ProcessStartMode.detached,
    );

    return true;
  }

  /// Windows: extracts zip and spawns detached batch script to swap files and relaunch.
  Future<bool> _installWindowsUpdate(File downloadedFile) async {
    final filePath = downloadedFile.path;
    final tempDir = downloadedFile.parent;
    final extractDir = Directory('${tempDir.path}\\extracted');
    await extractDir.create(recursive: true);

    // Extract zip via PowerShell Expand-Archive
    final extractResult = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-Command',
        'Expand-Archive -Path "$filePath" -DestinationPath "${extractDir.path}" -Force',
      ],
    );

    if (extractResult.exitCode != 0) {
      debugPrint('PowerShell Expand-Archive failed: ${extractResult.stderr}');
      return false;
    }

    // Determine running app directory
    final currentExe = Platform.resolvedExecutable;
    final targetDir = File(currentExe).parent.path;
    final pid = pidInstance;

    final scriptPath = '${tempDir.path}\\apply_update.bat';
    final scriptFile = File(scriptPath);

    final scriptContent = '''@echo off
timeout /t 1 /nobreak >nul
taskkill /F /PID $pid >nul 2>&1
timeout /t 1 /nobreak >nul

xcopy "${extractDir.path}\\*" "$targetDir\\" /E /Y /I /Q >nul

start "" "$currentExe"

rd /s /q "${tempDir.path}" >nul 2>&1
''';

    await scriptFile.writeAsString(scriptContent);

    // Spawn detached updater batch script
    await Process.start(
      'cmd.exe',
      ['/c', scriptPath],
      mode: ProcessStartMode.detached,
    );

    return true;
  }

  @visibleForTesting
  int get pidInstance => pid;
}
