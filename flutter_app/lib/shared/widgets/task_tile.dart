import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/task_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDone ? AppColors.surface.withOpacity(0.55) : AppColors.elevatedCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.cardBorder.withOpacity(0.4) : AppColors.cardBorder,
          width: 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap ?? onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Interactive Custom Checkbox
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: isDone ? AppColors.success : AppColors.textSecondary,
                      width: 2.0,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Title, Category, Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Duration pill
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              '${task.estimatedMinutes}m',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (task.priority == 'high') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HIGH',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // XP Reward Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.cardBorder.withOpacity(0.5)
                      : AppColors.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDone
                        ? Colors.transparent
                        : AppColors.primaryBlue.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt,
                      size: 13,
                      color: isDone ? AppColors.textMuted : AppColors.cyanHighlight,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+${task.xpReward} XP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppColors.textMuted : AppColors.cyanHighlight,
                      ),
                    ),
                  ],
                ),
              ),

              if (onDelete != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
