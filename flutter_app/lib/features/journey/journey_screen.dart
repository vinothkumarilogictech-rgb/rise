import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/app_provider.dart';
import '../../shared/widgets/mountain_painter.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _tabIndex = 0; // 0: Milestones, 1: Achievements, 2: XP Rules

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    final app = Provider.of<AppProvider>(context);
    final journey = app.journey;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Fullscreen Mountain Scene
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Summit Expedition',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: MountainScenePainter(
                          progressPercent: journey.mountainProgressPercent,
                          animationValue: _animation.value,
                          isFullScreen: true,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 45,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                journey.stageName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyanHighlight,
                                ),
                              ),
                              Text(
                                '${journey.totalXp} Total XP  •  Level ${journey.level}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            '${journey.mountainProgressPercent.toStringAsFixed(0)}% to Summit',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sub-navigation tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Trail Milestones'),
                    _buildTabButton(1, 'Achievements'),
                    _buildTabButton(2, 'XP Rules'),
                  ],
                ),
              ),
            ),
          ),

          // Dynamic Tab Content
          if (_tabIndex == 0) _buildMilestonesSliver(app),
          if (_tabIndex == 1) _buildAchievementsSliver(app),
          if (_tabIndex == 2) _buildXpRulesSliver(),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMilestonesSliver(AppProvider app) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) {
            final m = app.milestones[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: m.isCurrent
                    ? AppColors.primaryBlue.withOpacity(0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: m.isCurrent
                      ? AppColors.cyanHighlight
                      : (m.isReached ? AppColors.cardBorder : AppColors.cardBorder.withOpacity(0.5)),
                  width: m.isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.isReached ? AppColors.cyanHighlight : AppColors.elevatedCard,
                    ),
                    child: Center(
                      child: m.isReached
                          ? const Icon(Icons.check, size: 18, color: Colors.black)
                          : Text(
                              '${m.level}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              m.stageName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: m.isReached ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                            if (m.isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cyanHighlight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cyanHighlight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Requires ${m.xpRequired} total XP',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: app.milestones.length,
        ),
      ),
    );
  }

  Widget _buildAchievementsSliver(AppProvider app) {
    if (app.achievements.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Icon(Icons.military_tech_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text(
                'Complete your first task or focus session to unlock your expedition badges!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) {
            final a = app.achievements[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cyanHighlight.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, size: 20, color: AppColors.cyanHighlight),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          },
          childCount: app.achievements.length,
        ),
      ),
    );
  }

  Widget _buildXpRulesSliver() {
    final rules = [
      {'title': 'Complete Normal Task', 'xp': '+10 XP', 'desc': 'Completing any scheduled daily action item.'},
      {'title': 'Complete High-Priority Task', 'xp': '+15 XP', 'desc': 'Executing your core priority lever.'},
      {'title': 'Complete 25m Focus Flow', 'xp': '+10 XP', 'desc': 'Finishing a dedicated undistracted timer session.'},
      {'title': 'Write Daily Reflection', 'xp': '+5 XP', 'desc': 'Submitting today\'s RISE evening journal.'},
      {'title': 'XP Guarantee', 'xp': 'Fair & Idempotent', 'desc': 'XP is awarded once per task. No deductions for missed tasks.'},
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, idx) {
            final r = rules[idx];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['title']!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          r['desc']!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r['xp']!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: rules.length,
        ),
      ),
    );
  }
}
