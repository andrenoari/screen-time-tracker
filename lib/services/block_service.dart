import 'dart:io';

class BlockService {
  static Future<bool> blockProcess(String processName) async {
    if (!Platform.isWindows) return false;

    try {
      // Ensure we don't accidentally kill the tracker itself
      if (processName.toLowerCase().contains('screen_time_tracker')) {
        return false;
      }

      final result = await Process.run('taskkill', ['/F', '/IM', '$processName.exe']);
      return result.exitCode == 0;
    } catch (e) {
      print('Error killing process $processName: $e');
      return false;
    }
  }
}
