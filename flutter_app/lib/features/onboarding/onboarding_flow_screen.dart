import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/custom_buttons.dart';
import '../auth/auth_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Answers
  final TextEditingController _nameController = TextEditingController(text: 'Climber');
  final Set<String> _selectedGoals = {'GATE 2027 Electrical Engineering', 'Coding Independence'};
  double _availableMinutes = 120;
  String _reminderTime = '08:00';
  String _planningStyle = 'balanced';

  final List<String> _goalOptions = [
    'GATE 2027 Electrical Engineering',
    'Coding Independence & Software Depth',
    'Career Growth & High-Impact Delivery',
    'Rest, Sleep & Family Harmony',
    'Deep Work Focus & Habit Discipline',
  ];

  final List<Map<String, String>> _planningStyles = [
    {
      'id': 'gentle',
      'title': 'Gentle & Steady',
      'desc': 'Focus on building consistent momentum without high pressure.'
    },
    {
      'id': 'balanced',
      'title': 'Balanced Growth',
      'desc': 'Solid daily focus blocks paired with intentional rest.'
    },
    {
      'id': 'aggressive',
      'title': 'Intensive Peak',
      'desc': 'Maximized daily output for upcoming high-stakes targets.'
    },
  ];

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Proceed to Auth Registration with collected answers
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthScreen(
            initialIsRegister: true,
            presetDisplayName: _nameController.text.trim().isEmpty ? 'Climber' : _nameController.text.trim(),
            presetAvailableMinutes: _availableMinutes.round(),
            presetPlanningStyle: _planningStyle,
            presetReminderTime: _reminderTime,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final isActive = index <= _currentPage;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == _currentPage ? 24 : 8,
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? AppColors.cyanHighlight : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(initialIsRegister: true),
                ),
              );
            },
            child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (page) => setState(() => _currentPage = page),
        children: [
          _buildNameStep(),
          _buildGoalsStep(),
          _buildTimeStep(),
          _buildStyleStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GradientButton(
            text: _currentPage == 3 ? 'Create Account & Start' : 'Continue',
            icon: Icons.arrow_forward,
            onPressed: _nextPage,
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What should your AI Coach call you?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Personalizing your mountain expedition journey.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            style: const TextStyle(fontSize: 18, color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryBlue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are your primary goals?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all that you would like RISE to track and coach.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ..._goalOptions.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.elevatedCard : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: CheckboxListTile(
                value: isSelected,
                title: Text(
                  goal,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                activeColor: AppColors.primaryBlue,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedGoals.add(goal);
                    } else {
                      _selectedGoals.remove(goal);
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How much focused time do you have daily?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'RISE tailors realistic task durations so you avoid burnout.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.cyanHighlight, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    '${_availableMinutes.round()} Minutes',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _availableMinutes,
            min: 30,
            max: 360,
            divisions: 11,
            activeColor: AppColors.primaryBlue,
            inactiveColor: AppColors.cardBorder,
            onChanged: (val) => setState(() => _availableMinutes = val),
          ),
          const Center(
            child: Text(
              'Recommended: 120 minutes (Two 45m deep focus blocks + 30m review)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preferred planning philosophy',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'How should your AI coach calibrate daily workloads?',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ..._planningStyles.map((style) {
            final isSelected = _planningStyle == style['id'];
            return GestureDetector(
              onTap: () => setState(() => _planningStyle = style['id']!),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.elevatedCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: style['id']!,
                      groupValue: _planningStyle,
                      activeColor: AppColors.cyanHighlight,
                      onChanged: (val) => setState(() => _planningStyle = val!),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style['title']!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            style['desc']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
