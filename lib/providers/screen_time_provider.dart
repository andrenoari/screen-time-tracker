import 'package:flutter/foundation.dart';
import '../models/app_usage.dart';
import '../services/database_service.dart';
import '../services/process_tracker_service.dart';

class ScreenTimeProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService.instance;
  final ProcessTrackerService _processTracker = ProcessTrackerService();

  // Current state
  bool _isTracking = false;
  String _currentApp = '';
  String _currentWindowTitle = '';
  int _totalSecondsToday = 0;
  DateTime _selectedDate = DateTime.now();
  int _selectedDays = 1; // 1 = today, 7 = week, 30 = month

  // Usage data
  List<AppUsage> _todayUsage = [];
  List<AggregatedAppUsage> _aggregatedUsage = [];
  List<Map<String, dynamic>> _dailyUsage = [];

  // Getters
  bool get isTracking => _isTracking;
  String get currentApp => _currentApp;
  String get currentWindowTitle => _currentWindowTitle;
  int get totalSecondsToday => _totalSecondsToday;
  DateTime get selectedDate => _selectedDate;
  int get selectedDays => _selectedDays;
  List<AppUsage> get todayUsage => _todayUsage;
  List<AggregatedAppUsage> get aggregatedUsage => _aggregatedUsage;
  List<Map<String, dynamic>> get dailyUsage => _dailyUsage;

  String get formattedTotalTime {
    final hours = _totalSecondsToday ~/ 3600;
    final minutes = (_totalSecondsToday % 3600) ~/ 60;
    final seconds = _totalSecondsToday % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  ScreenTimeProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Set up callbacks
    _processTracker.onActiveWindowChanged = (processName, windowTitle) {
      _currentApp = processName;
      _currentWindowTitle = windowTitle;
      notifyListeners();
    };

    _processTracker.onTotalTimeUpdated = (totalSeconds) {
      _totalSecondsToday = totalSeconds;
      notifyListeners();
    };

    // Load initial data
    await loadTodayData();
    await loadDailyUsage();

    // Auto-start tracking
    startTracking();
  }

  void startTracking() {
    _processTracker.startTracking();
    _isTracking = true;
    notifyListeners();
  }

  void stopTracking() {
    _processTracker.stopTracking();
    _isTracking = false;
    notifyListeners();
  }

  void toggleTracking() {
    if (_isTracking) {
      stopTracking();
    } else {
      startTracking();
    }
  }

  // Methods to update settings
  void setTrackingInterval(int seconds) {
    _processTracker.setTrackingInterval(seconds);
  }

  void setIgnoredApps(List<String> apps) {
    _processTracker.customIgnoredApps = apps;
  }

  int get trackingInterval => _processTracker.trackingInterval;

  Future<void> loadTodayData() async {
    final today = DateTime.now();
    final startDate = DateTime(today.year, today.month, today.day);
    final endDate = startDate;

    await _loadUsageData(startDate, endDate);
  }

  Future<void> loadDataForDays(int days) async {
    _selectedDays = days;
    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month, today.day);
    final startDate = endDate.subtract(Duration(days: days - 1));

    await _loadUsageData(startDate, endDate);
    notifyListeners();
  }

  Future<void> _loadUsageData(DateTime startDate, DateTime endDate) async {
    final usageList = await _databaseService.getUsageForDateRange(startDate, endDate);
    _todayUsage = usageList;

    // Calculate total time
    int totalSeconds = 0;
    for (final usage in usageList) {
      totalSeconds += usage.usageSeconds;
    }
    _totalSecondsToday = totalSeconds;

    // Aggregate by process
    final Map<String, int> processUsage = {};
    for (final usage in usageList) {
      processUsage[usage.processName] = 
          (processUsage[usage.processName] ?? 0) + usage.usageSeconds;
    }

    // Convert to aggregated list
    _aggregatedUsage = processUsage.entries.map((entry) {
      final percentage = totalSeconds > 0 
          ? (entry.value / totalSeconds) * 100 
          : 0.0;
      
      return AggregatedAppUsage(
        processName: entry.key,
        displayName: _formatProcessName(entry.key),
        totalSeconds: entry.value,
        percentage: percentage,
      );
    }).toList();

    // Sort by usage
    _aggregatedUsage.sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

    notifyListeners();
  }

  Future<void> loadDailyUsage() async {
    _dailyUsage = await _databaseService.getDailyUsage(7);
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    loadDataForDays(1);
    notifyListeners();
  }

  String _formatProcessName(String processName) {
    // Convert process names to more readable format
    // e.g., "chrome" -> "Chrome", "Code" -> "VS Code"
    final displayNames = {
      'chrome': 'Google Chrome',
      'firefox': 'Firefox',
      'msedge': 'Microsoft Edge',
      'Code': 'VS Code',
      'WindowsTerminal': 'Terminal',
      'explorer': 'File Explorer',
      'Spotify': 'Spotify',
      'Discord': 'Discord',
      'slack': 'Slack',
      'Teams': 'Microsoft Teams',
      'OUTLOOK': 'Outlook',
      'WINWORD': 'Word',
      'EXCEL': 'Excel',
      'POWERPNT': 'PowerPoint',
      'notepad': 'Notepad',
      'Notion': 'Notion',
      'figma': 'Figma',
    };

    // Check for known apps (case insensitive)
    for (final entry in displayNames.entries) {
      if (processName.toLowerCase() == entry.key.toLowerCase()) {
        return entry.value;
      }
    }

    // Default: capitalize first letter
    if (processName.isEmpty) return processName;
    return processName[0].toUpperCase() + processName.substring(1);
  }

  @override
  void dispose() {
    _processTracker.dispose();
    super.dispose();
  }
}
