/// Represents a single app usage record
class AppUsage {
  final int? id;
  final String processName;
  final String windowTitle;
  final String? appPath;
  final int usageSeconds;
  final DateTime date;
  final DateTime lastActive;

  AppUsage({
    this.id,
    required this.processName,
    required this.windowTitle,
    this.appPath,
    required this.usageSeconds,
    required this.date,
    required this.lastActive,
  });

  /// Create AppUsage from database map
  factory AppUsage.fromMap(Map<String, dynamic> map) {
    return AppUsage(
      id: map['id'] as int?,
      processName: map['process_name'] as String,
      windowTitle: map['window_title'] as String,
      appPath: map['app_path'] as String?,
      usageSeconds: map['usage_seconds'] as int,
      date: DateTime.parse(map['date'] as String),
      lastActive: DateTime.parse(map['last_active'] as String),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'process_name': processName,
      'window_title': windowTitle,
      'app_path': appPath,
      'usage_seconds': usageSeconds,
      'date': date.toIso8601String().split('T')[0],
      'last_active': lastActive.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  AppUsage copyWith({
    int? id,
    String? processName,
    String? windowTitle,
    String? appPath,
    int? usageSeconds,
    DateTime? date,
    DateTime? lastActive,
  }) {
    return AppUsage(
      id: id ?? this.id,
      processName: processName ?? this.processName,
      windowTitle: windowTitle ?? this.windowTitle,
      appPath: appPath ?? this.appPath,
      usageSeconds: usageSeconds ?? this.usageSeconds,
      date: date ?? this.date,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  /// Format usage time as human readable string
  String get formattedUsageTime {
    final hours = usageSeconds ~/ 3600;
    final minutes = (usageSeconds % 3600) ~/ 60;
    final seconds = usageSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  String toString() {
    return 'AppUsage(processName: $processName, windowTitle: $windowTitle, usageSeconds: $usageSeconds)';
  }
}

/// Aggregated app usage for display
class AggregatedAppUsage {
  final String processName;
  final String displayName;
  final int totalSeconds;
  final double percentage;
  final String? iconPath;

  AggregatedAppUsage({
    required this.processName,
    required this.displayName,
    required this.totalSeconds,
    required this.percentage,
    this.iconPath,
  });

  String get formattedTime {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
