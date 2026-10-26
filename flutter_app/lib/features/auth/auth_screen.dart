import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../shared/widgets/custom_buttons.dart';
import '../shell/main_navigation_shell.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsRegister;
  final String? presetDisplayName;
  final int? presetAvailableMinutes;
  final String? presetPlanningStyle;
  final String? presetReminderTime;

  const AuthScreen({
    super.key,
    this.initialIsRegister = true,
    this.presetDisplayName,
    this.presetAvailableMinutes,
    this.presetPlanningStyle,
    this.presetReminderTime,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isRegister;
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    bool success = false;
    if (_isRegister) {
      success = await authProvider.register(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        displayName: widget.presetDisplayName,
        availableDailyMinutes: widget.presetAvailableMinutes ?? 120,
        planningStyle: widget.presetPlanningStyle ?? 'balanced',
        reminderTime: widget.presetReminderTime ?? '08:00',
      );
    } else {
      success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success) {
      if (!mounted) return;
      await appProvider.loadAllData();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
        (route) => false,
      );
    }
  }

  void _switchMode(bool register) {
    setState(() {
      _isRegister = register;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoading = auth.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isRegister ? 'Begin Your Expedition' : 'Welcome Back',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode Toggle Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          key: const Key('tab_create_account'),
                          onTap: isLoading ? null : () => _switchMode(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _isRegister ? AppColors.primaryGradient : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _isRegister ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          key: const Key('tab_sign_in'),
                          onTap: isLoading ? null : () => _switchMode(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: !_isRegister ? AppColors.primaryGradient : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: !_isRegister ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Error Message Banner
                if (auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(fontSize: 13, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Username Field
                TextFormField(
                  key: const Key('field_username'),
                  controller: _usernameController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Choose a unique username',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryBlue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Username cannot be empty';
                    }
                    if (trimmed.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (trimmed.length > 50) {
                      return 'Username cannot exceed 50 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(trimmed)) {
                      return 'Only letters, numbers, underscores, and dashes allowed';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  key: const Key('field_password'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !isLoading,
                  textInputAction: _isRegister ? TextInputAction.next : TextInputAction.done,
                  onFieldSubmitted: _isRegister ? null : (_) => _submit(),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Confirm Password Field (Registration only)
                if (_isRegister) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('field_confirm_password'),
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.primaryBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (val != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                // Action Button: "Create My Account" or "Sign In"
                GradientButton(
                  key: Key(_isRegister ? 'btn_create_account' : 'btn_sign_in'),
                  text: _isRegister ? 'Create My Account' : 'Sign In',
                  icon: _isRegister ? Icons.rocket_launch : Icons.login,
                  isLoading: isLoading,
                  onPressed: isLoading ? () {} : _submit,
                ),

                const SizedBox(height: 20),

                // Switch Mode Link
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : () => _switchMode(!_isRegister),
                    child: RichText(
                      text: TextSpan(
                        text: _isRegister ? 'Already have an account? ' : "Don't have an account? ",
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: _isRegister ? 'Sign In' : 'Create My Account',
                            style: const TextStyle(
                              color: AppColors.cyanHighlight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: Text(
                    _isRegister
                        ? 'Your data remains private and securely hashed.'
                        : 'Secure session with encrypted credential tokens.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
