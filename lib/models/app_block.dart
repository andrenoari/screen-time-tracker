class AppBlock {
  final String processName;
  final int? dailyLimitSeconds;
  final int? blockStartMinutes; // Minutes from midnight
  final int? blockEndMinutes;   // Minutes from midnight
  final bool isEnabled;

  const AppBlock({
    required this.processName,
    this.dailyLimitSeconds,
    this.blockStartMinutes,
    this.blockEndMinutes,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'processName': processName,
      'dailyLimitSeconds': dailyLimitSeconds,
      'blockStartMinutes': blockStartMinutes,
      'blockEndMinutes': blockEndMinutes,
      'isEnabled': isEnabled,
    };
  }

  factory AppBlock.fromJson(Map<String, dynamic> json) {
    return AppBlock(
      processName: json['processName'],
      dailyLimitSeconds: json['dailyLimitSeconds'],
      blockStartMinutes: json['blockStartMinutes'],
      blockEndMinutes: json['blockEndMinutes'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  AppBlock copyWith({
    String? processName,
    int? dailyLimitSeconds,
    int? blockStartMinutes,
    int? blockEndMinutes,
    bool? isEnabled,
  }) {
    return AppBlock(
      processName: processName ?? this.processName,
      dailyLimitSeconds: dailyLimitSeconds ?? this.dailyLimitSeconds,
      blockStartMinutes: blockStartMinutes ?? this.blockStartMinutes,
      blockEndMinutes: blockEndMinutes ?? this.blockEndMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
