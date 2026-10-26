import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../home/home_screen.dart';
import '../goals/goals_screen.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../journey/journey_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

class MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    GoalsScreen(),
    AICoachScreen(),
    JourneyScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.track_changes_rounded, 'Goals'),
                _buildNavItem(2, Icons.psychology_rounded, 'AI Coach', isSpecial: true),
                _buildNavItem(3, Icons.terrain_rounded, 'Journey'),
                _buildNavItem(4, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isSpecial = false}) {
    final isSelected = _currentIndex == index;

    if (isSpecial) {
      return GestureDetector(
        onTap: () => switchTab(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(isSelected ? 0.6 : 0.25),
                    blurRadius: isSelected ? 12 : 6,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.cyanHighlight : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => switchTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.cyanHighlight : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.cyanHighlight : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
