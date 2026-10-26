import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../core/services/notification_service.dart';
import '../analytics/analytics_screen.dart';
import '../onboarding/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late double _availableMinutes;
  late String _planningStyle;
  late String _reminderTime;
  late bool _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    _nameController = TextEditingController(text: user?.displayName ?? 'Climber');
    _availableMinutes = (user?.availableDailyMinutes ?? 120).toDouble();
    _planningStyle = user?.planningStyle ?? 'balanced';
    _reminderTime = user?.reminderTime ?? '08:00';
    _notificationsEnabled = user?.notificationEnabled ?? true;
  }

  void _saveSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.updatePreferences(
      displayName: _nameController.text.trim(),
      availableDailyMinutes: _availableMinutes.round(),
      planningStyle: _planningStyle,
      reminderTime: _reminderTime,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences updated successfully.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _testLocalNotification() async {
    final notifier = NotificationService();
    await notifier.requestPermission();
    await notifier.showInstantReminder(
      title: 'RISE Daily Focus',
      body: 'Time to climb! Your morning focus block is ready.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent to device.'),
        backgroundColor: AppColors.cyanHighlight,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Confirm Sign Out', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to sign out of RISE? Your progress is securely saved on the server.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final app = Provider.of<AppProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.cyanHighlight),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar & Rank Badge
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryBlue,
                      child: Text(
                        (user?.displayName.isNotEmpty == true ? user!.displayName[0] : 'C').toUpperCase(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'Climber',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      user?.username != null && user!.username.isNotEmpty ? '@${user.username}' : '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Level ${app.journey.level}  •  ${app.journey.stageName}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Analytics Quick Link
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bar_chart, color: AppColors.cyanHighlight),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Productivity & Progress Analytics',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'View completion rates, streaks, and focus metrics',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Personalization',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              // Edit Display Name
              TextField(
                controller: _nameController,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 16),

              // Available Time Slider
              Container(
                padding: const EdgeInsets.all(16),
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
                        const Text('Daily Study / Work Time', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        Text('${_availableMinutes.round()} mins', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight)),
                      ],
                    ),
                    Slider(
                      value: _availableMinutes,
                      min: 30,
                      max: 360,
                      divisions: 11,
                      activeColor: AppColors.primaryBlue,
                      inactiveColor: AppColors.cardBorder,
                      onChanged: (val) => setState(() => _availableMinutes = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Planning Style Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Planning Philosophy', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _planningStyle,
                      dropdownColor: AppColors.elevatedCard,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(border: InputBorder.none),
                      items: [
                        {'id': 'gentle', 'name': 'Gentle & Steady'},
                        {'id': 'balanced', 'name': 'Balanced Growth'},
                        {'id': 'aggressive', 'name': 'Intensive Peak'},
                      ].map((s) {
                        return DropdownMenuItem(value: s['id'], child: Text(s['name']!));
                      }).toList(),
                      onChanged: (val) => setState(() => _planningStyle = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Reminders & Notifications',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily Reminders', style: TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                      subtitle: const Text('Morning planning & focus nudges', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: _notificationsEnabled,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                    const Divider(color: AppColors.cardBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send Test Android Notification', style: TextStyle(fontSize: 13, color: AppColors.cyanHighlight)),
                      trailing: const Icon(Icons.send_outlined, size: 18, color: AppColors.cyanHighlight),
                      onTap: _testLocalNotification,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                  label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
