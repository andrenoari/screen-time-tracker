import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../models/app_usage.dart';
import 'database_service.dart';

/// Service to track the currently active window/process on Windows
class ProcessTrackerService {
  Timer? _trackingTimer;
  String? _currentProcessName;
  DateTime? _currentProcessStartTime;
  int _trackingIntervalSeconds = 1;
  bool _isTracking = false;

  // Custom ignored apps from user settings
  List<String> customIgnoredApps = [];

  final DatabaseService _databaseService = DatabaseService.instance;

  // Callbacks
  Function(String processName, String windowTitle)? onActiveWindowChanged;
  Function(int totalSecondsToday)? onTotalTimeUpdated;

  bool get isTracking => _isTracking;
  int get trackingInterval => _trackingIntervalSeconds;

  /// Get the current foreground window information
  WindowInfo? getForegroundWindowInfo() {
    try {
      final hwnd = GetForegroundWindow();
      if (hwnd == 0) return null;

      // Get window title
      final titleLength = GetWindowTextLength(hwnd);
      if (titleLength == 0) return null;

      final titleBuffer = wsalloc(titleLength + 1);
      GetWindowText(hwnd, titleBuffer, titleLength + 1);
      final windowTitle = titleBuffer.toDartString();
      free(titleBuffer);

      // Get process ID
      final processIdPtr = calloc<DWORD>();
      GetWindowThreadProcessId(hwnd, processIdPtr);
      final processId = processIdPtr.value;
      free(processIdPtr);

      if (processId == 0) return null;

      // Open process to get executable path
      final hProcess = OpenProcess(
        PROCESS_QUERY_LIMITED_INFORMATION,
        FALSE,
        processId,
      );

      if (hProcess == 0) return null;

      String processName = 'Unknown';
      String? processPath;

      // Get process executable path
      final pathBuffer = wsalloc(MAX_PATH);
      final pathSize = calloc<DWORD>();
      pathSize.value = MAX_PATH;

      if (QueryFullProcessImageName(hProcess, 0, pathBuffer, pathSize) != 0) {
        processPath = pathBuffer.toDartString();
        // Extract just the executable name
        final parts = processPath.split('\\');
        if (parts.isNotEmpty) {
          processName = parts.last.replaceAll('.exe', '');
        }
      }

      free(pathBuffer);
      free(pathSize);
      CloseHandle(hProcess);

      // Filter out system processes and empty windows
      if (_shouldIgnoreProcess(processName, windowTitle)) {
        return null;
      }

      return WindowInfo(
        processName: processName,
        windowTitle: windowTitle,
        processPath: processPath,
      );
    } catch (e) {
      print('Error getting foreground window: $e');
      return null;
    }
  }

  bool _shouldIgnoreProcess(String processName, String windowTitle) {
    // Ignore empty or minimal window titles
    if (windowTitle.isEmpty || windowTitle.length < 2) return true;

    // Ignore common system processes
    final ignoredProcesses = [
      'SearchHost',
      'ShellExperienceHost',
      'StartMenuExperienceHost',
      'LockApp',
      'TextInputHost',
      'SystemSettings',
      'ApplicationFrameHost',
    ];

    // Check built-in ignored processes
    if (ignoredProcesses.any(
      (p) => processName.toLowerCase().contains(p.toLowerCase()),
    )) {
      return true;
    }

    // Check user-defined ignored apps
    if (customIgnoredApps.any(
      (app) => processName.toLowerCase().contains(app.toLowerCase()) ||
               app.toLowerCase().contains(processName.toLowerCase()),
    )) {
      return true;
    }

    return false;
  }

  /// Start tracking active windows
  void startTracking() {
    if (_isTracking) return;

    _isTracking = true;
    _trackingTimer = Timer.periodic(
      Duration(seconds: _trackingIntervalSeconds),
      (_) => _trackActiveWindow(),
    );

    print('Process tracking started');
  }

  /// Stop tracking
  void stopTracking() {
    _isTracking = false;
    _trackingTimer?.cancel();
    _trackingTimer = null;

    // Save current session before stopping
    _saveCurrentSession();
    print('Process tracking stopped');
  }

  void _trackActiveWindow() async {
    final windowInfo = getForegroundWindowInfo();
    if (windowInfo == null) return;

    final now = DateTime.now();

    // Check if the active window changed
    if (_currentProcessName != windowInfo.processName) {
      // Save the previous session
      await _saveCurrentSession();

      // Start new session
      _currentProcessName = windowInfo.processName;
      _currentProcessStartTime = now;

      onActiveWindowChanged?.call(
        windowInfo.processName,
        windowInfo.windowTitle,
      );
    }

    // Record usage for current process
    if (_currentProcessName != null) {
      final usage = AppUsage(
        processName: windowInfo.processName,
        windowTitle: windowInfo.windowTitle,
        appPath: windowInfo.processPath,
        usageSeconds: _trackingIntervalSeconds,
        date: DateTime(now.year, now.month, now.day),
        lastActive: now,
      );

      await _databaseService.upsertAppUsage(usage);

      // Update total time
      final totalToday = await _databaseService.getTotalUsageForDate(
        DateTime(now.year, now.month, now.day),
      );
      onTotalTimeUpdated?.call(totalToday);
    }
  }

  Future<void> _saveCurrentSession() async {
    if (_currentProcessName == null || _currentProcessStartTime == null) return;

    // Session data is already being saved incrementally in _trackActiveWindow
    _currentProcessName = null;
    _currentProcessStartTime = null;
  }

  /// Set tracking interval in seconds
  void setTrackingInterval(int seconds) {
    _trackingIntervalSeconds = seconds;
    if (_isTracking) {
      stopTracking();
      startTracking();
    }
  }

  void dispose() {
    stopTracking();
  }
}

/// Information about a window
class WindowInfo {
  final String processName;
  final String windowTitle;
  final String? processPath;

  WindowInfo({
    required this.processName,
    required this.windowTitle,
    this.processPath,
  });

  @override
  String toString() {
    return 'WindowInfo(processName: $processName, windowTitle: $windowTitle)';
  }
}
