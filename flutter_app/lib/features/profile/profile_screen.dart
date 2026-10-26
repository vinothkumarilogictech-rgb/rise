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

  // Granular notification settings
  int _leadTimeMinutes = 15;
  String _quietHoursStart = '22:00';
  String _quietHoursEnd = '06:00';
  bool _notifyStudyReminders = true;
  bool _notifyDailyPlan = true;
  bool _notifyOverdue = true;
  bool _notifyMockTests = true;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    final user = auth.user;
    final prefs = app.notificationPreferences;

    _nameController = TextEditingController(text: user?.displayName ?? 'Climber');
    _availableMinutes = (user?.availableDailyMinutes ?? 120).toDouble();
    _planningStyle = user?.planningStyle ?? 'balanced';
    _reminderTime = user?.reminderTime ?? '08:00';
    _notificationsEnabled = prefs.notificationEnabled;

    _leadTimeMinutes = prefs.reminderLeadTimeMinutes;
    _quietHoursStart = prefs.quietHoursStart;
    _quietHoursEnd = prefs.quietHoursEnd;
    _notifyStudyReminders = prefs.notifyStudyReminders;
    _notifyDailyPlan = prefs.notifyDailyPlan;
    _notifyOverdue = prefs.notifyOverdue;
    _notifyMockTests = prefs.notifyMockTests;
  }

  void _saveSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);

    try {
      await auth.updatePreferences(
        displayName: _nameController.text.trim(),
        availableDailyMinutes: _availableMinutes.round(),
        planningStyle: _planningStyle,
        reminderTime: _reminderTime,
      );

      await app.updateNotificationPreferences({
        'notification_enabled': _notificationsEnabled,
        'reminder_lead_time_minutes': _leadTimeMinutes,
        'quiet_hours_start': _quietHoursStart,
        'quiet_hours_end': _quietHoursEnd,
        'notify_study_reminders': _notifyStudyReminders,
        'notify_daily_plan': _notifyDailyPlan,
        'notify_overdue': _notifyOverdue,
        'notify_mock_tests': _notifyMockTests,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences and notification settings updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text('Save failed: $e')),
      );
    }
  }

  void _testLocalNotification() async {
    final notifier = NotificationService();
    await notifier.requestPermission();
    await notifier.showInstantReminder(
      title: 'RISE Daily Focus (Local)',
      body: 'Time to climb! Your scheduled study session is starting soon.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test local notification triggered on device.'),
        backgroundColor: AppColors.cyanHighlight,
      ),
    );
  }

  void _testRemotePush() async {
    final app = Provider.of<AppProvider>(context, listen: false);
    final res = await app.sendTestPushNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'FCM test push sent.'),
        backgroundColor: AppColors.primaryBlue,
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
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile & Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Save', style: TextStyle(color: AppColors.cyanHighlight, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        (user?.displayName.isNotEmpty == true ? user!.displayName[0] : 'C').toUpperCase(),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Climber',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user?.username ?? 'climber'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.cyanHighlight),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'STAGE 1: BASE CAMP',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Productivity Analytics Shortcut Card
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
                    color: AppColors.elevatedCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insights, color: AppColors.cyanHighlight, size: 24),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Productivity & Timetable Analytics',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Planned vs. completed time, adherence, subject breakdown',
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
                'Reminders & Push Notifications (FCM)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

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
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notifications Master Switch', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      subtitle: const Text('Enable or pause all scheduled push reminders', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: _notificationsEnabled,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                    const Divider(color: AppColors.cardBorder),

                    // Reminder Lead Time Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reminder Lead Time', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        DropdownButton<int>(
                          value: _leadTimeMinutes,
                          dropdownColor: AppColors.elevatedCard,
                          items: const [
                            DropdownMenuItem(value: 5, child: Text('5 minutes before', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 10, child: Text('10 minutes before', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 15, child: Text('15 minutes before', style: TextStyle(color: AppColors.cyanHighlight, fontSize: 12))),
                            DropdownMenuItem(value: 30, child: Text('30 minutes before', style: TextStyle(color: Colors.white, fontSize: 12))),
                            DropdownMenuItem(value: 45, child: Text('45 minutes before', style: TextStyle(color: Colors.white, fontSize: 12))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _leadTimeMinutes = val);
                          },
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.cardBorder),

                    // Quiet Hours
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quiet Hours (Do Not Disturb)', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        Text('$_quietHoursStart - $_quietHoursEnd', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('Scheduled reminders falling in quiet hours are suppressed silently.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const Divider(color: AppColors.cardBorder),

                    // Category Toggles
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Study Session Reminders', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      subtitle: const Text('Upcoming sessions from timetable', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: _notifyStudyReminders,
                      activeColor: AppColors.cyanHighlight,
                      onChanged: (val) => setState(() => _notifyStudyReminders = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Daily AI Study Recommendations', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      subtitle: const Text('Personalized Grok morning briefing', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      value: _notifyDailyPlan,
                      activeColor: AppColors.cyanHighlight,
                      onChanged: (val) => setState(() => _notifyDailyPlan = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Overdue Task Reminders', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      value: _notifyOverdue,
                      activeColor: AppColors.cyanHighlight,
                      onChanged: (val) => setState(() => _notifyOverdue = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mock Test Alerts', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                      value: _notifyMockTests,
                      activeColor: AppColors.cyanHighlight,
                      onChanged: (val) => setState(() => _notifyMockTests = val),
                    ),
                    const Divider(color: AppColors.cardBorder),

                    // Action buttons
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send Test Remote Push (FCM Backend)', style: TextStyle(fontSize: 13, color: AppColors.cyanHighlight)),
                      trailing: const Icon(Icons.cloud_upload_outlined, size: 18, color: AppColors.cyanHighlight),
                      onTap: _testRemotePush,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send Test Local Notification', style: TextStyle(fontSize: 13, color: AppColors.primaryBlue)),
                      trailing: const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.primaryBlue),
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
