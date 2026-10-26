class DailyPointModel {
  final String date;
  final String dayName;
  final int completedTasks;
  final int totalTasks;
  final int focusMinutes;
  final int xpEarned;

  DailyPointModel({
    required this.date,
    required this.dayName,
    required this.completedTasks,
    required this.totalTasks,
    required this.focusMinutes,
    required this.xpEarned,
  });

  factory DailyPointModel.fromJson(Map<String, dynamic> json) {
    return DailyPointModel(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      completedTasks: json['completed_tasks'] ?? 0,
      totalTasks: json['total_tasks'] ?? 0,
      focusMinutes: json['focus_minutes'] ?? 0,
      xpEarned: json['xp_earned'] ?? 0,
    );
  }
}

class GoalProgressModel {
  final String goalId;
  final String title;
  final String category;
  final double progressPercentage;
  final int totalTasks;
  final int completedTasks;

  GoalProgressModel({
    required this.goalId,
    required this.title,
    required this.category,
    required this.progressPercentage,
    required this.totalTasks,
    required this.completedTasks,
  });

  factory GoalProgressModel.fromJson(Map<String, dynamic> json) {
    return GoalProgressModel(
      goalId: json['goal_id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      totalTasks: json['total_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
    );
  }
}

class AnalyticsOverviewModel {
  final int totalTasksCompleted;
  final double completionRatePercentage;
  final int currentStreak;
  final int bestStreak;
  final int totalFocusMinutes;
  final int totalXp;
  final int journalEntriesCount;
  final int todayCompletedTasks;
  final int todayTotalTasks;
  final List<DailyPointModel> weeklyTrend;
  final List<GoalProgressModel> goalProgress;

  AnalyticsOverviewModel({
    this.totalTasksCompleted = 0,
    this.completionRatePercentage = 0.0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.totalFocusMinutes = 0,
    this.totalXp = 0,
    this.journalEntriesCount = 0,
    this.todayCompletedTasks = 0,
    this.todayTotalTasks = 0,
    this.weeklyTrend = const [],
    this.goalProgress = const [],
  });

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawTrend = json['weekly_trend'] as List<dynamic>? ?? [];
    final rawGoals = json['goal_progress'] as List<dynamic>? ?? [];
    return AnalyticsOverviewModel(
      totalTasksCompleted: json['total_tasks_completed'] ?? 0,
      completionRatePercentage: (json['completion_rate_percentage'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['current_streak'] ?? 0,
      bestStreak: json['best_streak'] ?? 0,
      totalFocusMinutes: json['total_focus_minutes'] ?? 0,
      totalXp: json['total_xp'] ?? 0,
      journalEntriesCount: json['journal_entries_count'] ?? 0,
      todayCompletedTasks: json['today_completed_tasks'] ?? 0,
      todayTotalTasks: json['today_total_tasks'] ?? 0,
      weeklyTrend: rawTrend.map((t) => DailyPointModel.fromJson(t)).toList(),
      goalProgress: rawGoals.map((g) => GoalProgressModel.fromJson(g)).toList(),
    );
  }
}
