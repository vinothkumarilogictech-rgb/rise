import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/app_provider.dart';
import '../../models/goal_model.dart';
import '../../shared/widgets/custom_buttons.dart';
import '../../shared/widgets/empty_state.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'GATE 2027',
    'Coding Independence',
    'Career & Work',
    'Personal Well-being',
  ];

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetDateController = TextEditingController(text: '2027-02-15');
    String category = 'GATE 2027';
    final milestoneControllers = [
      TextEditingController(text: 'Core Theory Foundation'),
      TextEditingController(text: 'Practice 10 High-Yield Problems'),
      TextEditingController(text: 'Review Errors in Journal'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create New Long-Term Goal',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Goal Title',
                    hintText: 'e.g., Master Power Electronics & Machines',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.elevatedCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: AppColors.elevatedCard,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.elevatedCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: ['GATE 2027', 'Coding Independence', 'Career & Work', 'Personal Well-being', 'General'].map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) => setModalState(() => category = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Description / Purpose',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.elevatedCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Milestones (Steps to summit):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ...List.generate(milestoneControllers.length, (idx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: milestoneControllers[idx],
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.flag_outlined, size: 16, color: AppColors.primaryBlue),
                        hintText: 'Milestone ${idx + 1}',
                        filled: true,
                        fillColor: AppColors.elevatedCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                GradientButton(
                  text: 'Save Goal',
                  icon: Icons.check,
                  onPressed: () {
                    if (titleController.text.trim().isNotEmpty) {
                      final app = Provider.of<AppProvider>(context, listen: false);
                      final milestones = milestoneControllers
                          .map((c) => c.text.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();

                      app.addGoal(
                        title: titleController.text.trim(),
                        category: category,
                        description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                        targetDate: targetDateController.text.trim(),
                        milestoneTitles: milestones,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAiPlanDialog(BuildContext context, GoalModel goal) async {
    final app = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.cyanHighlight),
      ),
    );

    try {
      final generatedTasks = await app.generateAiPlan(
        goalTitle: goal.title,
        category: goal.category,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show generated plan review sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetCtx) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.violetAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.cyanHighlight, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Generated Action Plan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          goal.title,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Review and customize these manageable steps before adding them to your schedule:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: generatedTasks.length,
                  itemBuilder: (ctx, idx) {
                    final item = generatedTasks[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['title'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${item['xp_reward'] ?? 10} XP',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cyanHighlight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description'] ?? '',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (item['why_it_matters'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 12, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item['why_it_matters'],
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                text: 'Add All to Today\'s Schedule',
                icon: Icons.playlist_add_check,
                onPressed: () {
                  for (final item in generatedTasks) {
                    app.addTask(
                      title: item['title'] ?? 'Goal Task',
                      description: item['description'],
                      goalId: goal.id,
                      category: goal.category,
                      section: item['section'] ?? 'Main Priorities',
                      priority: item['priority'] ?? 'medium',
                      estimatedMinutes: item['estimated_minutes'] ?? 25,
                      xpReward: item['xp_reward'] ?? 10,
                      whyItMatters: item['why_it_matters'],
                    );
                  }
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tasks added to your daily schedule!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate AI plan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final filteredGoals = _selectedCategory == 'All'
        ? app.goals
        : app.goals.where((g) => g.category.contains(_selectedCategory)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Long-Term Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.cyanHighlight),
            onPressed: () => _showAddGoalDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Goals List
            Expanded(
              child: filteredGoals.isEmpty
                  ? EmptyStateView(
                      icon: Icons.track_changes,
                      title: 'No goals in this category',
                      message: 'Set clear targets to unlock your potential and build consistency.',
                      buttonText: 'Create Goal',
                      onButtonPressed: () => _showAddGoalDialog(context),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredGoals.length,
                      itemBuilder: (ctx, idx) {
                        final goal = filteredGoals[idx];
                        return _buildGoalCard(context, goal);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, GoalModel goal) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final completedCount = goal.milestones.where((m) => m.isCompleted).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cyanHighlight,
                  ),
                ),
              ),
              if (goal.targetDate != null)
                Text(
                  'Target: ${goal.targetDate}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goal.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (goal.description != null) ...[
            const SizedBox(height: 4),
            Text(
              goal.description!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),

          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Milestones: $completedCount / ${goal.milestones.length}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                '${goal.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (goal.progressPercentage / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppColors.elevatedCard,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 14),

          // Milestones checklist
          if (goal.milestones.isNotEmpty) ...[
            ...goal.milestones.map((m) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: InkWell(
                  onTap: () => app.toggleGoalMilestone(goal.id, m.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Icon(
                        m.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: m.isCompleted ? AppColors.success : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: m.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                            decoration: m.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // AI Plan Generation Trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAiPlanDialog(context, goal),
                icon: const Icon(Icons.auto_awesome, size: 14, color: AppColors.cyanHighlight),
                label: const Text(
                  'Generate AI Action Plan',
                  style: TextStyle(fontSize: 12, color: AppColors.cyanHighlight),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
