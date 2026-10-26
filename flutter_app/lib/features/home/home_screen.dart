import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/widgets/mountain_hero_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/task_tile.dart';
import '../../shared/widgets/custom_buttons.dart';
import '../../shared/widgets/empty_state.dart';
import '../shell/main_navigation_shell.dart';
import '../focus/focus_screen.dart';
import '../journal/journal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSection = 'All';

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showAddTaskSheet(BuildContext context) {
    final titleController = TextEditingController();
    final whyController = TextEditingController();
    String section = 'Main Priorities';
    String priority = 'medium';
    int minutes = 25;
    String category = 'General';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Task',
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
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g., Solve 5 GATE EE network theorems',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.elevatedCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              // Section Selector
              DropdownButtonFormField<String>(
                value: section,
                dropdownColor: AppColors.elevatedCard,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Section',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.elevatedCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: ['Morning Focus', 'Main Priorities', 'Evening Review'].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) => setModalState(() => section = val!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: priority,
                      dropdownColor: AppColors.elevatedCard,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.elevatedCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: ['low', 'medium', 'high'].map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setModalState(() => priority = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: '$minutes',
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Duration (m)',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.elevatedCard,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onChanged: (val) => minutes = int.tryParse(val) ?? 25,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: 'Save Task',
                icon: Icons.check,
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    final app = Provider.of<AppProvider>(context, listen: false);
                    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    app.addTask(
                      title: titleController.text.trim(),
                      category: category,
                      section: section,
                      priority: priority,
                      estimatedMinutes: minutes,
                      xpReward: priority == 'high' ? 15 : 10,
                      dueDate: todayStr,
                      whyItMatters: whyController.text.trim().isNotEmpty ? whyController.text.trim() : null,
                    );
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showXpCelebrationDialog(int xp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cyanHighlight.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt, color: AppColors.cyanHighlight, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              '+$xp XP Earned!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your position along the mountain has advanced.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Keep Climbing'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final app = Provider.of<AppProvider>(context);
    final user = auth.user;
    final now = DateTime.now();
    final dateFormatted = DateFormat('EEEE, MMM d').format(now);

    final featured = app.featuredFocusTask;
    final filteredTasks = _selectedSection == 'All'
        ? app.tasks
        : app.tasks.where((t) => t.section == _selectedSection).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => app.loadAllData(),
          color: AppColors.cyanHighlight,
          backgroundColor: AppColors.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Personalized Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getTimeGreeting()}, ${user?.displayName ?? 'Climber'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Icon(Icons.notifications_none, size: 20, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final shell = context.findAncestorStateOfType<MainNavigationShellState>();
                            shell?.switchTab(4); // Open Profile
                          },
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryBlue,
                            child: Text(
                              (user?.displayName.isNotEmpty == true ? user!.displayName[0] : 'C').toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // AI Daily Message Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.cyanHighlight, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          app.journey.dailyMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Signature Mountain Journey Hero Card
                MountainHeroCard(
                  journey: app.journey,
                  onTap: () {
                    final shell = context.findAncestorStateOfType<MainNavigationShellState>();
                    shell?.switchTab(3); // Open Journey Screen
                  },
                ),

                const SizedBox(height: 18),

                // 3. Daily Progress Overview
                DailyProgressOverviewCard(
                  completedTasks: app.completedTasksTodayCount,
                  totalTasks: app.tasks.length,
                  xpEarnedToday: app.completedTasksTodayCount * 10,
                  currentStreak: app.journey.currentStreakDays,
                ),

                const SizedBox(height: 22),

                // 4. Today's Focus (Featured Main Task)
                if (featured != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Main Focus",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'KEY LEVER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyanHighlight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final xp = await app.completeTask(featured.id);
                                if (xp > 0) _showXpCelebrationDialog(xp);
                              },
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primaryBlue, width: 2),
                                ),
                                child: const Icon(Icons.check, size: 16, color: Colors.transparent),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    featured.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (featured.whyItMatters != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      featured.whyItMatters!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  '${featured.estimatedMinutes} mins',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '+${featured.xpReward} XP',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cyanHighlight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FocusScreen(
                                      initialTask: featured,
                                      durationMinutes: featured.estimatedMinutes,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Start Focus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],

                // 5. Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionButton(
                        icon: Icons.psychology_outlined,
                        label: 'AI Coach',
                        iconColor: AppColors.violetAccent,
                        onTap: () {
                          final shell = context.findAncestorStateOfType<MainNavigationShellState>();
                          shell?.switchTab(2);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickActionButton(
                        icon: Icons.add_task,
                        label: 'Add Task',
                        iconColor: AppColors.cyanHighlight,
                        onTap: () => _showAddTaskSheet(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickActionButton(
                        icon: Icons.timer_outlined,
                        label: 'Focus Flow',
                        iconColor: AppColors.primaryBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const FocusScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: QuickActionButton(
                        icon: Icons.edit_note,
                        label: 'Journal',
                        iconColor: AppColors.warning,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JournalScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 6. Today's Task List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddTaskSheet(context),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.primaryBlue),
                      label: const Text('Add Task', style: TextStyle(color: AppColors.primaryBlue)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Section Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'Morning Focus', 'Main Priorities', 'Evening Review'].map((sec) {
                      final isSelected = _selectedSection == sec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(sec),
                          selected: isSelected,
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (_) => setState(() => _selectedSection = sec),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                if (filteredTasks.isEmpty) ...[
                  EmptyStateView(
                    icon: Icons.check_circle_outline,
                    title: 'No tasks scheduled in this section',
                    message: 'Take a moment to add a focused step or ask AI Coach to plan.',
                    buttonText: 'Add Task',
                    onButtonPressed: () => _showAddTaskSheet(context),
                  ),
                ] else ...[
                  ...filteredTasks.map((t) {
                    return TaskTile(
                      task: t,
                      onToggle: () async {
                        if (!t.isCompleted) {
                          final xp = await app.completeTask(t.id);
                          if (xp > 0) _showXpCelebrationDialog(xp);
                        } else {
                          await app.reopenTask(t.id);
                        }
                      },
                      onDelete: () => app.deleteTask(t.id),
                    );
                  }),
                ],

                const SizedBox(height: 20),

                // 7. Daily Reflection Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_stories, color: AppColors.warning, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Reflection',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'What did you do today that your future self will thank you for?',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryBlue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const JournalScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
