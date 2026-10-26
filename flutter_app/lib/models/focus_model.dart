class FocusSessionModel {
  final String id;
  final String label;
  final int plannedDurationMinutes;
  final int actualDurationMinutes;
  final bool completed;
  final int xpAwarded;
  final DateTime startedAt;

  FocusSessionModel({
    required this.id,
    required this.label,
    required this.plannedDurationMinutes,
    required this.actualDurationMinutes,
    required this.completed,
    required this.xpAwarded,
    required this.startedAt,
  });

  factory FocusSessionModel.fromJson(Map<String, dynamic> json) {
    return FocusSessionModel(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Deep Focus Session',
      plannedDurationMinutes: json['planned_duration_minutes'] ?? 25,
      actualDurationMinutes: json['actual_duration_minutes'] ?? 25,
      completed: json['completed'] ?? true,
      xpAwarded: json['xp_awarded'] ?? 10,
      startedAt: DateTime.tryParse(json['started_at'] ?? '') ?? DateTime.now(),
    );
  }
}
