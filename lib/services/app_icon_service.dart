import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service to extract and cache Windows application icons.
class AppIconService {
  static final AppIconService _instance = AppIconService._();
  static AppIconService get instance => _instance;
  AppIconService._();

  /// Cache of process name -> icon file path
  final Map<String, String?> _cache = {};

  /// Directory where extracted icons are stored
  String? _iconDir;

  Future<String> _getIconDir() async {
    if (_iconDir != null) return _iconDir!;
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, 'app_icons'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _iconDir = dir.path;
    return _iconDir!;
  }

  /// Get the cached icon path for a process name, or extract it.
  /// Returns null if icon extraction fails.
  Future<String?> getIconPath(String processName) async {
    // Normalize
    final key = processName.toLowerCase();

    // Check memory cache
    if (_cache.containsKey(key)) return _cache[key];

    // Check disk cache
    final dir = await _getIconDir();
    final cachedFile = File(p.join(dir, '$key.png'));
    if (await cachedFile.exists()) {
      _cache[key] = cachedFile.path;
      return cachedFile.path;
    }

    // Extract icon using PowerShell
    try {
      final outputPath = cachedFile.path.replaceAll('\\', '\\\\');
      final script = '''
Add-Type -AssemblyName System.Drawing
\$process = Get-Process -Name "${key.replaceAll('.exe', '')}" -ErrorAction SilentlyContinue | Select-Object -First 1
if (\$process -and \$process.MainModule) {
  \$icon = [System.Drawing.Icon]::ExtractAssociatedIcon(\$process.MainModule.FileName)
  if (\$icon) {
    \$bmp = \$icon.ToBitmap()
    \$bmp.Save("$outputPath", [System.Drawing.Imaging.ImageFormat]::Png)
    \$bmp.Dispose()
    \$icon.Dispose()
    Write-Output "OK"
  }
}
''';

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]).timeout(const Duration(seconds: 5));

      if (result.exitCode == 0 &&
          result.stdout.toString().trim().contains('OK') &&
          await cachedFile.exists()) {
        _cache[key] = cachedFile.path;
        return cachedFile.path;
      }
    } catch (_) {
      // Extraction failed — fall through
    }

    // Mark as failed so we don't retry
    _cache[key] = null;
    return null;
  }

  /// Pre-fetch icons for a list of process names.
  Future<void> prefetchIcons(List<String> processNames) async {
    await Future.wait(
      processNames.map((name) => getIconPath(name)),
    );
  }

  /// Clear the icon cache.
  Future<void> clearCache() async {
    _cache.clear();
    final dir = await _getIconDir();
    final d = Directory(dir);
    if (await d.exists()) {
      await d.delete(recursive: true);
      await d.create(recursive: true);
    }
  }
}
