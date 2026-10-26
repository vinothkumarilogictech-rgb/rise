class MilestoneModel {
  final int level;
  final int xpRequired;
  final String stageName;
  final bool isReached;
  final bool isCurrent;

  MilestoneModel({
    required this.level,
    required this.xpRequired,
    required this.stageName,
    required this.isReached,
    required this.isCurrent,
  });

  factory MilestoneModel.fromJson(Map<String, dynamic> json) {
    return MilestoneModel(
      level: json['level'] ?? 1,
      xpRequired: json['xp_required'] ?? 0,
      stageName: json['stage_name'] ?? 'First Step',
      isReached: json['is_reached'] ?? false,
      isCurrent: json['is_current'] ?? false,
    );
  }
}

class AchievementModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String icon;

  AchievementModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? 'mountain',
    );
  }
}

class JourneySummaryModel {
  final int level;
  final String stageName;
  final int totalXp;
  final int baseLevelXp;
  final int nextLevelXp;
  final int xpToNextLevel;
  final double progressRatio;
  final double mountainProgressPercent;
  final int currentStreakDays;
  final int tasksCompletedCount;
  final int focusMinutesTotal;
  final String dailyMessage;

  JourneySummaryModel({
    this.level = 1,
    this.stageName = 'First Step',
    this.totalXp = 0,
    this.baseLevelXp = 0,
    this.nextLevelXp = 100,
    this.xpToNextLevel = 100,
    this.progressRatio = 0.0,
    this.mountainProgressPercent = 0.0,
    this.currentStreakDays = 0,
    this.tasksCompletedCount = 0,
    this.focusMinutesTotal = 0,
    this.dailyMessage = 'Every focused session moves you closer to your summit.',
  });

  factory JourneySummaryModel.fromJson(Map<String, dynamic> json) {
    return JourneySummaryModel(
      level: json['level'] ?? 1,
      stageName: json['stage_name'] ?? 'First Step',
      totalXp: json['total_xp'] ?? 0,
      baseLevelXp: json['base_level_xp'] ?? 0,
      nextLevelXp: json['next_level_xp'] ?? 100,
      xpToNextLevel: json['xp_to_next_level'] ?? 100,
      progressRatio: (json['progress_ratio'] as num?)?.toDouble() ?? 0.0,
      mountainProgressPercent: (json['mountain_progress_percent'] as num?)?.toDouble() ?? 0.0,
      currentStreakDays: json['current_streak_days'] ?? 0,
      tasksCompletedCount: json['tasks_completed_count'] ?? 0,
      focusMinutesTotal: json['focus_minutes_total'] ?? 0,
      dailyMessage: json['daily_message'] ?? 'Every focused session moves you closer to your summit.',
    );
  }
}
