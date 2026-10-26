import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/journey_model.dart';
import 'mountain_painter.dart';

class MountainHeroCard extends StatefulWidget {
  final JourneySummaryModel journey;
  final VoidCallback onTap;

  const MountainHeroCard({
    super.key,
    required this.journey,
    required this.onTap,
  });

  @override
  State<MountainHeroCard> createState() => _MountainHeroCardState();
}

class _MountainHeroCardState extends State<MountainHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardGlow.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Mountain Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: MountainScenePainter(
                      progressPercent: widget.journey.mountainProgressPercent,
                      animationValue: _animation.value,
                      isFullScreen: false,
                    ),
                  );
                },
              ),
            ),

            // Top Status Overlay: Stage & Level
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.terrain, color: AppColors.cyanHighlight, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.journey.stageName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LVL ${widget.journey.level}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content: XP Progress & Motivational Line
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.cyanHighlight, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.journey.totalXp} XP',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${widget.journey.xpToNextLevel} XP to Level ${widget.journey.level + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: widget.journey.progressRatio.clamp(0.0, 1.0),
                        backgroundColor: AppColors.cardBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyanHighlight),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Summit is ${widget.journey.mountainProgressPercent.toStringAsFixed(0)}% conquered',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'View Journey',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 14, color: AppColors.primaryBlue),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
