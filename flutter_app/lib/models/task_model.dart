class TaskModel {
  final String id;
  final String? goalId;
  final String title;
  final String? description;
  final String category;
  final String section;
  final String priority;
  final int estimatedMinutes;
  final int xpReward;
  bool isCompleted;
  final String? dueDate;
  final String? whyItMatters;
  final int orderIndex;

  TaskModel({
    required this.id,
    this.goalId,
    required this.title,
    this.description,
    this.category = 'General',
    this.section = 'Main Priorities',
    this.priority = 'medium',
    this.estimatedMinutes = 25,
    this.xpReward = 10,
    this.isCompleted = false,
    this.dueDate,
    this.whyItMatters,
    this.orderIndex = 0,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      goalId: json['goal_id'],
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? 'General',
      section: json['section'] ?? 'Main Priorities',
      priority: json['priority'] ?? 'medium',
      estimatedMinutes: json['estimated_minutes'] ?? 25,
      xpReward: json['xp_reward'] ?? 10,
      isCompleted: json['is_completed'] ?? false,
      dueDate: json['due_date'],
      whyItMatters: json['why_it_matters'],
      orderIndex: json['order_index'] ?? 0,
    );
  }

  TaskModel copyWith({
    bool? isCompleted,
    String? title,
    String? description,
    String? section,
    String? priority,
    int? estimatedMinutes,
  }) {
    return TaskModel(
      id: id,
      goalId: goalId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category,
      section: section ?? this.section,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      xpReward: xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate,
      whyItMatters: whyItMatters,
      orderIndex: orderIndex,
    );
  }
}
