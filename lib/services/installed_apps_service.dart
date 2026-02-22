import 'dart:io';

class RunningApp {
  final String processName;
  final String windowTitle;

  RunningApp({
    required this.processName,
    required this.windowTitle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunningApp &&
          runtimeType == other.runtimeType &&
          processName.toLowerCase() == other.processName.toLowerCase();

  @override
  int get hashCode => processName.toLowerCase().hashCode;
}

class InstalledAppsService {
  /// Fetches a list of currently running applications that have observable window titles.
  static Future<List<RunningApp>> getRunningApps() async {
    final apps = <RunningApp>[];

    if (!Platform.isWindows) {
      return apps;
    }

    try {
      // Use powershell to get processes with main window titles
      // This filters out background services and generic host processes
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Get-Process | Where-Object { \$_.MainWindowTitle -ne "" } | Select-Object Name, MainWindowTitle | ConvertTo-Csv -NoTypeInformation'
      ]);

      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        
        // Skip header line (index 0)
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;

          // CSV parsing for "Name","MainWindowTitle"
          final parts = line.split('","');
          if (parts.length >= 2) {
            String processName = parts[0].replaceAll('"', '');
            // Append .exe as that's what we usually track in the process tracker
            if (!processName.toLowerCase().endsWith('.exe')) {
              processName += '.exe';
            }
            
            final windowTitle = parts[1].replaceAll('"', '');

            // Filter out self and common system overlays
            final lowerName = processName.toLowerCase();
            if (lowerName != 'screen_time_tracker.exe' &&
                lowerName != 'textinputhost.exe' &&
                lowerName != 'applicationframehost.exe') {
              apps.add(RunningApp(
                processName: processName,
                windowTitle: windowTitle,
              ));
            }
          }
        }
      }
    } catch (e) {
      // Fallback or error logging
    }

    // Convert to Set and back to List to remove duplicates (based on processName)
    final uniqueApps = apps.toSet().toList();
    
    // Sort alphabetically by processName
    uniqueApps.sort((a, b) => a.processName.compareTo(b.processName));
    
    return uniqueApps;
  }
}
