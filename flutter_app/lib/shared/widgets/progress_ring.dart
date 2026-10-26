import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class DailyProgressOverviewCard extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final int xpEarnedToday;
  final int currentStreak;

  const DailyProgressOverviewCard({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    required this.xpEarnedToday,
    required this.currentStreak,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks).clamp(0.0, 1.0);
    final percent = (ratio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 7,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Stats Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Today's Progress",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (currentStreak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, size: 13, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text(
                              '$currentStreak d',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatPill(
                      Icons.check_circle_outline,
                      '$completedTasks / $totalTasks',
                      'Tasks',
                      AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _buildStatPill(
                      Icons.bolt,
                      '+$xpEarnedToday XP',
                      'Earned',
                      AppColors.cyanHighlight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevatedCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
