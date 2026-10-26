class GoalMilestoneModel {
  final String id;
  final String title;
  bool isCompleted;
  final int orderIndex;

  GoalMilestoneModel({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.orderIndex = 0,
  });

  factory GoalMilestoneModel.fromJson(Map<String, dynamic> json) {
    return GoalMilestoneModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      orderIndex: json['order_index'] ?? 0,
    );
  }
}

class GoalModel {
  final String id;
  final String title;
  final String category;
  final String? description;
  final String? targetDate;
  final String status;
  double progressPercentage;
  final List<GoalMilestoneModel> milestones;

  GoalModel({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.targetDate,
    this.status = 'active',
    this.progressPercentage = 0.0,
    this.milestones = const [],
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['milestones'] as List<dynamic>? ?? [];
    return GoalModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      description: json['description'],
      targetDate: json['target_date'],
      status: json['status'] ?? 'active',
      progressPercentage: (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      milestones: rawMilestones.map((m) => GoalMilestoneModel.fromJson(m)).toList(),
    );
  }
}
