class UserModel {
  final String id;
  final String username;
  final String displayName;
  final int availableDailyMinutes;
  final String planningStyle;
  final String reminderTime;
  final bool notificationEnabled;

  UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.availableDailyMinutes = 120,
    this.planningStyle = 'balanced',
    this.reminderTime = '08:00',
    this.notificationEnabled = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? prefs}) {
    final rawUsername = json['username'] ?? json['email'] ?? '';
    final rawDisplayName = json['display_name'] ?? (rawUsername.isNotEmpty ? rawUsername : 'Climber');
    return UserModel(
      id: json['id'] ?? '',
      username: rawUsername,
      displayName: rawDisplayName,
      availableDailyMinutes: prefs?['available_daily_minutes'] ?? 120,
      planningStyle: prefs?['planning_style'] ?? 'balanced',
      reminderTime: prefs?['reminder_time'] ?? '08:00',
      notificationEnabled: prefs?['notification_enabled'] ?? true,
    );
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    int? availableDailyMinutes,
    String? planningStyle,
    String? reminderTime,
    bool? notificationEnabled,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      availableDailyMinutes: availableDailyMinutes ?? this.availableDailyMinutes,
      planningStyle: planningStyle ?? this.planningStyle,
      reminderTime: reminderTime ?? this.reminderTime,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}
