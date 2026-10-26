import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/goal_model.dart';
import '../models/task_model.dart';
import '../models/journey_model.dart';
import '../models/focus_model.dart';
import '../models/journal_model.dart';
import '../models/analytics_model.dart';

class AppProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;

  JourneySummaryModel _journey = JourneySummaryModel();
  List<MilestoneModel> _milestones = [];
  List<AchievementModel> _achievements = [];
  List<GoalModel> _goals = [];
  List<TaskModel> _tasks = [];
  List<FocusSessionModel> _focusSessions = [];
  List<JournalEntryModel> _journalEntries = [];
  AnalyticsOverviewModel _analytics = AnalyticsOverviewModel();

  // AI Chat state
  final List<Map<String, String>> _aiChatHistory = [];
  bool _isAiReplying = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  JourneySummaryModel get journey => _journey;
  List<MilestoneModel> get milestones => _milestones;
  List<AchievementModel> get achievements => _achievements;
  List<GoalModel> get goals => _goals;
  List<TaskModel> get tasks => _tasks;
  List<FocusSessionModel> get focusSessions => _focusSessions;
  List<JournalEntryModel> get journalEntries => _journalEntries;
  AnalyticsOverviewModel get analytics => _analytics;
  List<Map<String, String>> get aiChatHistory => _aiChatHistory;
  bool get isAiReplying => _isAiReplying;

  // Filtered tasks
  List<TaskModel> get morningTasks => _tasks.where((t) => t.section == 'Morning Focus').toList();
  List<TaskModel> get priorityTasks => _tasks.where((t) => t.section == 'Main Priorities').toList();
  List<TaskModel> get eveningTasks => _tasks.where((t) => t.section == 'Evening Review').toList();

  TaskModel? get featuredFocusTask {
    final uncompleted = _tasks.where((t) => !t.isCompleted).toList();
    if (uncompleted.isEmpty) return null;
    return uncompleted.firstWhere(
      (t) => t.priority == 'high',
      orElse: () => uncompleted.first,
    );
  }

  int get completedTasksTodayCount => _tasks.where((t) => t.isCompleted).length;
  double get todayCompletionRate => _tasks.isEmpty ? 0.0 : completedTasksTodayCount / _tasks.length;

  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadJourneyInternal(),
        _loadGoalsInternal(),
        _loadTasksInternal(),
        _loadAnalyticsInternal(),
        _loadJournalInternal(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadJourneyInternal() async {
    try {
      final summaryRes = await _api.get('/journey/summary');
      _journey = JourneySummaryModel.fromJson(summaryRes);

      final milestonesRes = await _api.get('/journey/milestones');
      if (milestonesRes is List) {
        _milestones = milestonesRes.map((m) => MilestoneModel.fromJson(m)).toList();
      }

      final achRes = await _api.get('/journey/achievements');
      if (achRes is List) {
        _achievements = achRes.map((a) => AchievementModel.fromJson(a)).toList();
      }
    } catch (_) {}
  }

  Future<void> _loadGoalsInternal() async {
    try {
      final res = await _api.get('/goals');
      if (res is List) {
        _goals = res.map((g) => GoalModel.fromJson(g)).toList();
      }
    } catch (_) {}
  }

  Future<void> _loadTasksInternal() async {
    try {
      final res = await _api.get('/tasks');
      if (res is List) {
        _tasks = res.map((t) => TaskModel.fromJson(t)).toList();
      }
    } catch (_) {}
  }

  Future<void> _loadAnalyticsInternal() async {
    try {
      final res = await _api.get('/analytics/overview');
      _analytics = AnalyticsOverviewModel.fromJson(res);
    } catch (_) {}
  }

  Future<void> _loadJournalInternal() async {
    try {
      final res = await _api.get('/journal');
      if (res is List) {
        _journalEntries = res.map((j) => JournalEntryModel.fromJson(j)).toList();
      }
    } catch (_) {}
  }

  // --- Task Operations ---
  Future<void> addTask({
    required String title,
    String? description,
    String? goalId,
    String category = 'General',
    String section = 'Main Priorities',
    String priority = 'medium',
    int estimatedMinutes = 25,
    int xpReward = 10,
    String? dueDate,
    String? whyItMatters,
  }) async {
    try {
      final res = await _api.post('/tasks', body: {
        'title': title,
        'description': description,
        'goal_id': goalId,
        'category': category,
        'section': section,
        'priority': priority,
        'estimated_minutes': estimatedMinutes,
        'xp_reward': xpReward,
        'due_date': dueDate,
        'why_it_matters': whyItMatters,
      });
      final created = TaskModel.fromJson(res);
      _tasks.insert(0, created);
      notifyListeners();
      await _loadAnalyticsInternal();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> completeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return 0;

    // Optimistic completion
    _tasks[taskIndex].isCompleted = true;
    notifyListeners();

    try {
      final res = await _api.post('/tasks/$taskId/complete');
      final xpAwarded = res['xp_awarded'] as int? ?? 0;
      await _loadJourneyInternal();
      await _loadAnalyticsInternal();
      return xpAwarded;
    } catch (e) {
      // Revert if failed
      _tasks[taskIndex].isCompleted = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reopenTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    _tasks[taskIndex].isCompleted = false;
    notifyListeners();

    try {
      await _api.post('/tasks/$taskId/reopen');
      await _loadJourneyInternal();
      await _loadAnalyticsInternal();
    } catch (e) {
      _tasks[taskIndex].isCompleted = true;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    try {
      await _api.delete('/tasks/$taskId');
      await _loadAnalyticsInternal();
    } catch (_) {}
  }

  // --- Goal Operations ---
  Future<void> addGoal({
    required String title,
    required String category,
    String? description,
    String? targetDate,
    List<String> milestoneTitles = const [],
  }) async {
    try {
      final res = await _api.post('/goals', body: {
        'title': title,
        'category': category,
        'description': description,
        'target_date': targetDate,
        'milestones': milestoneTitles.map((t) => {'title': t, 'is_completed': false}).toList(),
      });
      final created = GoalModel.fromJson(res);
      _goals.insert(0, created);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleGoalMilestone(String goalId, String milestoneId) async {
    final goalIndex = _goals.indexWhere((g) => g.id == goalId);
    if (goalIndex == -1) return;

    try {
      final res = await _api.post('/goals/$goalId/milestones/$milestoneId/toggle');
      _goals[goalIndex] = GoalModel.fromJson(res);
      notifyListeners();
    } catch (_) {}
  }

  // --- Focus Operations ---
  Future<int> completeFocusSession({
    required String label,
    required int durationMinutes,
  }) async {
    try {
      final res = await _api.post('/focus/sessions', body: {
        'label': label,
        'planned_duration_minutes': durationMinutes,
        'actual_duration_minutes': durationMinutes,
        'completed': true,
      });
      final xpAwarded = res['xp_awarded'] as int? ?? 10;
      await _loadJourneyInternal();
      await _loadAnalyticsInternal();
      return xpAwarded;
    } catch (e) {
      return 0;
    }
  }

  // --- Journal Operations ---
  Future<int> saveJournalEntry({
    required String date,
    required String content,
    String mood = 'focused',
    String? promptsAnswered,
    String? imageUrl,
  }) async {
    try {
      final res = await _api.post('/journal', body: {
        'date': date,
        'content': content,
        'mood': mood,
        'prompts_answered': promptsAnswered,
        'image_url': imageUrl,
      });
      final entry = JournalEntryModel.fromJson(res['entry']);
      _journalEntries.removeWhere((e) => e.date == date);
      _journalEntries.insert(0, entry);
      final xpAwarded = res['xp_awarded'] as int? ?? 5;
      await _loadJourneyInternal();
      await _loadAnalyticsInternal();
      notifyListeners();
      return xpAwarded;
    } catch (e) {
      rethrow;
    }
  }

  // --- AI Operations ---
  Future<List<Map<String, dynamic>>> generateAiPlan({
    required String goalTitle,
    String category = 'General',
    String? context,
  }) async {
    try {
      final res = await _api.post('/ai/plan', body: {
        'goal_title': goalTitle,
        'goal_category': category,
        'context': context,
      });
      final rawTasks = res['tasks'] as List<dynamic>? ?? [];
      return rawTasks.cast<Map<String, dynamic>>();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendAiMessage(String message) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty || _isAiReplying) return;

    // Capture conversation history prior to adding the new user message
    final previousHistory = _aiChatHistory
        .map((m) => {'role': m['role'] ?? 'user', 'content': m['content'] ?? ''})
        .toList();

    _aiChatHistory.add({'role': 'user', 'content': cleanMessage});
    _isAiReplying = true;
    notifyListeners();

    try {
      final res = await _api.post('/ai/chat', body: {
        'message': cleanMessage,
        'history': previousHistory,
      });
      final reply = (res['reply'] as String?)?.trim();
      if (reply != null && reply.isNotEmpty) {
        _aiChatHistory.add({'role': 'assistant', 'content': reply});
      } else {
        _aiChatHistory.add({
          'role': 'assistant',
          'content': 'Unable to reach the AI service. Please try again.'
        });
      }
    } on ApiException catch (e) {
      _aiChatHistory.add({
        'role': 'assistant',
        'content': e.message.isNotEmpty
            ? e.message
            : 'Unable to reach the AI service. Please try again.'
      });
    } catch (_) {
      _aiChatHistory.add({
        'role': 'assistant',
        'content': 'Unable to reach the AI service. Please try again.'
      });
    } finally {
      _isAiReplying = false;
      notifyListeners();
    }
  }
}
