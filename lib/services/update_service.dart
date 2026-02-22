import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  final bool isUpdateAvailable;
  final String latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;

  UpdateInfo({
    required this.isUpdateAvailable,
    required this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
  });
}

class UpdateService {
  static const String _repoOwner = 'andrenoari';
  static const String _repoName = 'screen-time-tracker';
  static const String _latestReleaseUrl = 'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  Future<UpdateInfo> checkForUpdates() async {
    try {
      // 1. Get current version
      final packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      // 2. Fetch latest release from GitHub
      final response = await http.get(Uri.parse(_latestReleaseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String latestTag = data['tag_name'] as String;
        // Strip 'v' prefix if present (e.g., v1.0.0 -> 1.0.0)
        final String latestVersion = latestTag.startsWith('v') 
            ? latestTag.substring(1) 
            : latestTag;

        // 3. Simple version comparison
        final bool isUpdateAvailable = _isVersionHigher(latestVersion, currentVersion);

        // 4. Find the installer asset (.exe)
        String? downloadUrl;
        final List<dynamic> assets = data['assets'] as List<dynamic>;
        for (final asset in assets) {
          final String name = asset['name'] as String;
          if (name.endsWith('.exe')) {
            downloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }

        return UpdateInfo(
          isUpdateAvailable: isUpdateAvailable,
          latestVersion: latestVersion,
          downloadUrl: downloadUrl,
          releaseNotes: data['body'] as String?,
        );
      } else {
        throw Exception('Failed to load release info');
      }
    } catch (e) {
      print('Update check error: $e');
      rethrow;
    }
  }

  bool _isVersionHigher(String latest, String current) {
    List<int> latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < latestParts.length; i++) {
      int currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (latestParts[i] > currentPart) return true;
      if (latestParts[i] < currentPart) return false;
    }
    return false;
  }
}
