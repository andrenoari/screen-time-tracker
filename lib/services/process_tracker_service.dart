import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../models/app_usage.dart';
import '../models/app_block.dart';
import 'database_service.dart';
import 'block_service.dart';

/// Service to track the currently active window/process on Windows
class ProcessTrackerService {
  Timer? _trackingTimer;
  String? _currentProcessName;
  DateTime? _currentProcessStartTime;
  int _trackingIntervalSeconds = 1;
  int _idleTimeoutMinutes = 5;
  
  // Notification fields
  bool _enableDailyGoal = false;
  int _dailyGoalHours = 4;
  bool _enableBreakReminders = false;
  int _breakReminderIntervalMinutes = 60;
  
  int _continuousActiveSeconds = 0;
  bool _dailyGoalTriggered = false;

  bool _pauseOnLock = true;
  bool _isTracking = false;

  // Custom ignored apps from user settings
  List<String> customIgnoredApps = [];

  // Blocking Rules
  List<AppBlock> blockRules = [];

  final DatabaseService _databaseService = DatabaseService.instance;

  // Callbacks
  Function(String processName, String windowTitle)? onActiveWindowChanged;
  Function(int totalSecondsToday)? onTotalTimeUpdated;
  Function(int breakMinutes)? onBreakReminderReached;
  Function(int goalHours)? onDailyGoalReached;
  Function(String processName)? onBlockedAppAttempt;

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

  /// Get system idle time in seconds
  int _getIdleTimeSeconds() {
    try {
      final lastInputInfo = calloc<LASTINPUTINFO>();
      lastInputInfo.ref.cbSize = sizeOf<LASTINPUTINFO>();

      if (GetLastInputInfo(lastInputInfo) != 0) {
        final tickCount = GetTickCount();
        final idleMilliseconds = tickCount - lastInputInfo.ref.dwTime;
        free(lastInputInfo);
        return idleMilliseconds ~/ 1000;
      }
      free(lastInputInfo);
    } catch (e) {
      print('Error getting idle time: $e');
    }
    return 0; // Assume not idle on error
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
    // Check for user activity early to avoid recording blank usage
    if (_idleTimeoutMinutes > 0) {
      final idleSeconds = _getIdleTimeSeconds();
      if (idleSeconds >= _idleTimeoutMinutes * 60) {
        // User is idle. We should pause tracking for this interval.
        // Also close out any existing session so we don't skew the last active time
        await _saveCurrentSession();
        _continuousActiveSeconds = 0; // Reset consecutive break timer
        return;
      }
    }

    final hwnd = GetForegroundWindow();
    if (_pauseOnLock && hwnd == 0) {
      // If foreground window is 0 (Desktop or Lock Screen in some states) and pauseOnLock is on
      await _saveCurrentSession();
      _continuousActiveSeconds = 0;
      return;
    }

    final windowInfo = getForegroundWindowInfo();
    if (windowInfo == null) return;

    // --- Blocking Check ---
    if (await _shouldBlockProcess(windowInfo.processName)) {
      await BlockService.blockProcess(windowInfo.processName);
      onBlockedAppAttempt?.call(windowInfo.processName);
      return; 
    }

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

      // --- Notifications Logic ---
      _continuousActiveSeconds += _trackingIntervalSeconds;
      
      // 1. Break Reminders
      if (_enableBreakReminders && _breakReminderIntervalMinutes > 0) {
        if (_continuousActiveSeconds >= _breakReminderIntervalMinutes * 60) {
          onBreakReminderReached?.call(_breakReminderIntervalMinutes);
          _continuousActiveSeconds = 0; // Reset consecutive active timer
        }
      }

      // 2. Daily Goal
      if (_enableDailyGoal && _dailyGoalHours > 0 && !_dailyGoalTriggered) {
        if (totalToday >= _dailyGoalHours * 3600) {
          onDailyGoalReached?.call(_dailyGoalHours);
          _dailyGoalTriggered = true; // Only trigger once per day
        }
      }
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

  /// Set idle timeout in minutes
  void setIdleTimeout(int minutes) {
    _idleTimeoutMinutes = minutes;
  }

  void setPauseOnLock(bool value) {
    _pauseOnLock = value;
  }

  Future<bool> _shouldBlockProcess(String processName) async {
    final now = DateTime.now();
    final timeNowMin = now.hour * 60 + now.minute;

    for (final rule in blockRules) {
      if (!rule.isEnabled) continue;
      
      if (processName.toLowerCase().contains(rule.processName.toLowerCase())) {
        // 1. Check Schedule Block
        if (rule.blockStartMinutes != null && rule.blockEndMinutes != null) {
          if (_isTimeBetween(timeNowMin, rule.blockStartMinutes!, rule.blockEndMinutes!)) {
            return true;
          }
        }

        // 2. Check Daily Limit
        if (rule.dailyLimitSeconds != null) {
          final usageToday = await _databaseService.getAppUsageForProcess(
            rule.processName,
            DateTime(now.year, now.month, now.day),
          );
          
          if (usageToday != null && usageToday.usageSeconds >= rule.dailyLimitSeconds!) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _isTimeBetween(int nowMin, int startMin, int endMin) {
    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin <= endMin;
    } else {
      // Overnight block (e.g., 22:00 to 06:00)
      return nowMin >= startMin || nowMin <= endMin;
    }
  }

  void configureNotifications({
    required bool enableDailyGoal,
    required int dailyGoalHours,
    required bool enableBreakReminders,
    required int breakReminderIntervalMinutes,
  }) {
    _enableDailyGoal = enableDailyGoal;
    _dailyGoalHours = dailyGoalHours;
    _enableBreakReminders = enableBreakReminders;
    _breakReminderIntervalMinutes = breakReminderIntervalMinutes;
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
