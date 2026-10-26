class TimetableSessionItemModel {
  String id;
  String date;
  String? weekday;
  String startTime;
  String endTime;
  String subject;
  String topic;
  String sessionType;
  int estimatedMinutes;
  String priority;
  String? goalId;
  String? notes;
  bool isSelected;

  TimetableSessionItemModel({
    required this.id,
    required this.date,
    this.weekday,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.topic,
    this.sessionType = 'study',
    this.estimatedMinutes = 60,
    this.priority = 'medium',
    this.goalId,
    this.notes,
    this.isSelected = true,
  });

  factory TimetableSessionItemModel.fromJson(Map<String, dynamic> json) {
    return TimetableSessionItemModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      weekday: json['weekday'],
      startTime: json['start_time'] ?? '08:00 AM',
      endTime: json['end_time'] ?? '09:00 AM',
      subject: json['subject'] ?? 'General',
      topic: json['topic'] ?? 'Topic',
      sessionType: json['session_type'] ?? 'study',
      estimatedMinutes: json['estimated_minutes'] ?? 60,
      priority: json['priority'] ?? 'medium',
      goalId: json['goal_id'],
      notes: json['notes'],
      isSelected: json['is_selected'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'weekday': weekday,
      'start_time': startTime,
      'end_time': endTime,
      'subject': subject,
      'topic': topic,
      'session_type': sessionType,
      'estimated_minutes': estimatedMinutes,
      'priority': priority,
      'goal_id': goalId,
      'notes': notes,
      'is_selected': isSelected,
    };
  }
}

class TimetableExtractResponseModel {
  final String filename;
  final String extractedTextPreview;
  final int totalSessionsFound;
  final List<TimetableSessionItemModel> sessions;
  final String source;

  TimetableExtractResponseModel({
    required this.filename,
    required this.extractedTextPreview,
    required this.totalSessionsFound,
    required this.sessions,
    this.source = 'ai',
  });

  factory TimetableExtractResponseModel.fromJson(Map<String, dynamic> json) {
    final list = (json['sessions'] as List? ?? [])
        .map((item) => TimetableSessionItemModel.fromJson(item))
        .toList();

    return TimetableExtractResponseModel(
      filename: json['filename'] ?? '',
      extractedTextPreview: json['extracted_text_preview'] ?? '',
      totalSessionsFound: json['total_sessions_found'] ?? list.length,
      sessions: list,
      source: json['source'] ?? 'ai',
    );
  }
}

class DailyStudyPlanModel {
  final String id;
  final String planDate;
  final String recommendationText;
  final String? reasoningSummary;
  final List<String> taskReferences;
  final String source;
  final String createdAt;

  DailyStudyPlanModel({
    required this.id,
    required this.planDate,
    required this.recommendationText,
    this.reasoningSummary,
    this.taskReferences = const [],
    required this.source,
    required this.createdAt,
  });

  factory DailyStudyPlanModel.fromJson(Map<String, dynamic> json) {
    return DailyStudyPlanModel(
      id: json['id'] ?? '',
      planDate: json['plan_date'] ?? '',
      recommendationText: json['recommendation_text'] ?? '',
      reasoningSummary: json['reasoning_summary'],
      taskReferences: (json['task_references'] as List? ?? []).map((e) => e.toString()).toList(),
      source: json['source'] ?? 'grok',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class NotificationPreferencesModel {
  final bool notificationEnabled;
  final int reminderLeadTimeMinutes;
  final String preferredPlanningTime;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String timezone;
  final bool notifyStudyReminders;
  final bool notifyDailyPlan;
  final bool notifyOverdue;
  final bool notifyMockTests;

  NotificationPreferencesModel({
    this.notificationEnabled = true,
    this.reminderLeadTimeMinutes = 15,
    this.preferredPlanningTime = '07:00',
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '06:00',
    this.timezone = 'Asia/Kolkata',
    this.notifyStudyReminders = true,
    this.notifyDailyPlan = true,
    this.notifyOverdue = true,
    this.notifyMockTests = true,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      notificationEnabled: json['notification_enabled'] ?? true,
      reminderLeadTimeMinutes: json['reminder_lead_time_minutes'] ?? 15,
      preferredPlanningTime: json['preferred_planning_time'] ?? '07:00',
      quietHoursStart: json['quiet_hours_start'] ?? '22:00',
      quietHoursEnd: json['quiet_hours_end'] ?? '06:00',
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      notifyStudyReminders: json['notify_study_reminders'] ?? true,
      notifyDailyPlan: json['notify_daily_plan'] ?? true,
      notifyOverdue: json['notify_overdue'] ?? true,
      notifyMockTests: json['notify_mock_tests'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_enabled': notificationEnabled,
      'reminder_lead_time_minutes': reminderLeadTimeMinutes,
      'preferred_planning_time': preferredPlanningTime,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'timezone': timezone,
      'notify_study_reminders': notifyStudyReminders,
      'notify_daily_plan': notifyDailyPlan,
      'notify_overdue': notifyOverdue,
      'notify_mock_tests': notifyMockTests,
    };
  }
}
