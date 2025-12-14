import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'dart:io';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // General Settings
  bool _startWithWindows = false;
  bool _minimizeToTray = true;
  bool _showNotifications = true;

  // Tracking Settings
  int _idleTimeout = 5; // minutes
  int _trackingInterval = 1; // seconds
  List<String> _ignoredApps = [];

  // Goals Settings
  bool _enableDailyGoal = false;
  int _dailyGoalHours = 4;
  bool _enableBreakReminders = false;
  int _breakReminderInterval = 60; // minutes

  // Privacy Settings
  bool _blurAppNames = false;
  bool _pauseOnLock = true;

  // Data Settings
  int _dataRetentionDays = 30;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get startWithWindows => _startWithWindows;
  bool get minimizeToTray => _minimizeToTray;
  bool get showNotifications => _showNotifications;
  int get idleTimeout => _idleTimeout;
  int get trackingInterval => _trackingInterval;
  List<String> get ignoredApps => List.unmodifiable(_ignoredApps);
  bool get enableDailyGoal => _enableDailyGoal;
  int get dailyGoalHours => _dailyGoalHours;
  bool get enableBreakReminders => _enableBreakReminders;
  int get breakReminderInterval => _breakReminderInterval;
  bool get blurAppNames => _blurAppNames;
  bool get pauseOnLock => _pauseOnLock;
  int get dataRetentionDays => _dataRetentionDays;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load all settings from SharedPreferences
    _startWithWindows = _prefs.getBool('startWithWindows') ?? false;
    _minimizeToTray = _prefs.getBool('minimizeToTray') ?? true;
    _showNotifications = _prefs.getBool('showNotifications') ?? true;
    _idleTimeout = _prefs.getInt('idleTimeout') ?? 5;
    _trackingInterval = _prefs.getInt('trackingInterval') ?? 1;
    _ignoredApps = _prefs.getStringList('ignoredApps') ?? [];
    _enableDailyGoal = _prefs.getBool('enableDailyGoal') ?? false;
    _dailyGoalHours = _prefs.getInt('dailyGoalHours') ?? 4;
    _enableBreakReminders = _prefs.getBool('enableBreakReminders') ?? false;
    _breakReminderInterval = _prefs.getInt('breakReminderInterval') ?? 60;
    _blurAppNames = _prefs.getBool('blurAppNames') ?? false;
    _pauseOnLock = _prefs.getBool('pauseOnLock') ?? true;
    _dataRetentionDays = _prefs.getInt('dataRetentionDays') ?? 30;

    // Setup launch at startup
    if (Platform.isWindows) {
      launchAtStartup.setup(
        appName: 'Screen Time Tracker',
        appPath: Platform.resolvedExecutable,
      );
      
      // Sync the actual state
      final isEnabled = await launchAtStartup.isEnabled();
      if (isEnabled != _startWithWindows) {
        _startWithWindows = isEnabled;
        await _prefs.setBool('startWithWindows', isEnabled);
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  // General Settings Setters
  Future<void> setStartWithWindows(bool value) async {
    if (_startWithWindows == value) return;
    
    _startWithWindows = value;
    await _prefs.setBool('startWithWindows', value);

    if (Platform.isWindows) {
      if (value) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    }

    notifyListeners();
  }

  Future<void> setMinimizeToTray(bool value) async {
    if (_minimizeToTray == value) return;
    
    _minimizeToTray = value;
    await _prefs.setBool('minimizeToTray', value);
    notifyListeners();
  }

  Future<void> setShowNotifications(bool value) async {
    if (_showNotifications == value) return;
    
    _showNotifications = value;
    await _prefs.setBool('showNotifications', value);
    notifyListeners();
  }

  // Tracking Settings Setters
  Future<void> setIdleTimeout(int value) async {
    if (_idleTimeout == value) return;
    
    _idleTimeout = value;
    await _prefs.setInt('idleTimeout', value);
    notifyListeners();
  }

  Future<void> setTrackingInterval(int value) async {
    if (_trackingInterval == value) return;
    
    _trackingInterval = value;
    await _prefs.setInt('trackingInterval', value);
    notifyListeners();
  }

  Future<void> addIgnoredApp(String appName) async {
    if (_ignoredApps.contains(appName)) return;
    
    _ignoredApps.add(appName);
    await _prefs.setStringList('ignoredApps', _ignoredApps);
    notifyListeners();
  }

  Future<void> removeIgnoredApp(String appName) async {
    if (!_ignoredApps.contains(appName)) return;
    
    _ignoredApps.remove(appName);
    await _prefs.setStringList('ignoredApps', _ignoredApps);
    notifyListeners();
  }

  bool isAppIgnored(String appName) {
    return _ignoredApps.any((ignored) => 
      appName.toLowerCase().contains(ignored.toLowerCase())
    );
  }

  // Goals Settings Setters
  Future<void> setEnableDailyGoal(bool value) async {
    if (_enableDailyGoal == value) return;
    
    _enableDailyGoal = value;
    await _prefs.setBool('enableDailyGoal', value);
    notifyListeners();
  }

  Future<void> setDailyGoalHours(int value) async {
    if (_dailyGoalHours == value) return;
    
    _dailyGoalHours = value;
    await _prefs.setInt('dailyGoalHours', value);
    notifyListeners();
  }

  Future<void> setEnableBreakReminders(bool value) async {
    if (_enableBreakReminders == value) return;
    
    _enableBreakReminders = value;
    await _prefs.setBool('enableBreakReminders', value);
    notifyListeners();
  }

  Future<void> setBreakReminderInterval(int value) async {
    if (_breakReminderInterval == value) return;
    
    _breakReminderInterval = value;
    await _prefs.setInt('breakReminderInterval', value);
    notifyListeners();
  }

  // Privacy Settings Setters
  Future<void> setBlurAppNames(bool value) async {
    if (_blurAppNames == value) return;
    
    _blurAppNames = value;
    await _prefs.setBool('blurAppNames', value);
    notifyListeners();
  }

  Future<void> setPauseOnLock(bool value) async {
    if (_pauseOnLock == value) return;
    
    _pauseOnLock = value;
    await _prefs.setBool('pauseOnLock', value);
    notifyListeners();
  }

  // Data Settings Setters
  Future<void> setDataRetentionDays(int value) async {
    if (_dataRetentionDays == value) return;
    
    _dataRetentionDays = value;
    await _prefs.setInt('dataRetentionDays', value);
    notifyListeners();
  }

  // Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _startWithWindows = false;
    _minimizeToTray = true;
    _showNotifications = true;
    _idleTimeout = 5;
    _trackingInterval = 1;
    _ignoredApps = [];
    _enableDailyGoal = false;
    _dailyGoalHours = 4;
    _enableBreakReminders = false;
    _breakReminderInterval = 60;
    _blurAppNames = false;
    _pauseOnLock = true;
    _dataRetentionDays = 30;

    await _prefs.clear();
    
    if (Platform.isWindows) {
      await launchAtStartup.disable();
    }

    notifyListeners();
  }
}
