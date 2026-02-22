import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  bool _initialized = false;
  bool _enabled = true;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    
    await localNotifier.setup(
      appName: 'Screen Time Tracker',
      shortcutPolicy: ShortcutPolicy.requireCreate,
    );
    
    _initialized = true;
  }

  Future<void> showBreakReminder(int minutes) async {
    if (!_initialized) await initialize();

    if (!_enabled) return;

    final notification = LocalNotification(
      title: "Time for a Break!",
      body: "You've been active for $minutes minutes. Stretch your legs and rest your eyes!",
    );

    // Show the notification
    await notification.show();
  }

  Future<void> showDailyGoalReached(int hours) async {
    if (!_initialized) await initialize();

    if (!_enabled) return;

    final notification = LocalNotification(
      title: "Daily Goal Reached",
      body: "You've reached your daily screen time limit of $hours hours!",
    );

    await notification.show();
  }

  Future<void> showBlockedApp(String processName) async {
    if (!_initialized) await initialize();

    if (!_enabled) return;

    final notification = LocalNotification(
      title: "App Blocked",
      body: "$processName has been closed because of your current blocking rules.",
    );

    await notification.show();
  }
}
