import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/app_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final analytics = app.analytics;
    final weekly = analytics.weeklyTrend;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Productivity Analytics'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Completion Rate',
                      '${analytics.completionRatePercentage.toStringAsFixed(0)}%',
                      Icons.pie_chart_outline,
                      AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Active Streak',
                      '${analytics.currentStreak} Days',
                      Icons.local_fire_department,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Focus Time',
                      '${analytics.totalFocusMinutes} Mins',
                      Icons.timer_outlined,
                      AppColors.cyanHighlight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'Total Earned XP',
                      '${analytics.totalXp} XP',
                      Icons.bolt,
                      AppColors.violetAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 7-Day Completion Bar Visualization
              const Text(
                '7-Day Consistency Trend',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: weekly.map((point) {
                        final maxVal = 5;
                        final ratio = (point.completedTasks / maxVal).clamp(0.08, 1.0);
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${point.completedTasks}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 22,
                              height: 100 * ratio,
                              decoration: BoxDecoration(
                                gradient: point.completedTasks > 0
                                    ? AppColors.primaryGradient
                                    : null,
                                color: point.completedTasks == 0 ? AppColors.elevatedCard : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              point.dayName,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Goal Breakdown
              const Text(
                'Goal-Wise Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ...analytics.goalProgress.map((g) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
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
                              g.title,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            '${g.progressPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (g.progressPercentage / 100.0).clamp(0.0, 1.0),
                          backgroundColor: AppColors.elevatedCard,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${g.completedTasks} of ${g.totalTasks} tasks completed',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
