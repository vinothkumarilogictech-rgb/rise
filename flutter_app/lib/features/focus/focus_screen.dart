import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/app_provider.dart';
import '../../models/task_model.dart';
import '../../shared/widgets/custom_buttons.dart';

class FocusScreen extends StatefulWidget {
  final TaskModel? initialTask;
  final int durationMinutes;

  const FocusScreen({
    super.key,
    this.initialTask,
    this.durationMinutes = 25,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late int _totalSeconds;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.durationMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _labelController = TextEditingController(
      text: widget.initialTask != null
          ? 'Focus: ${widget.initialTask!.title}'
          : 'Deep Focus Flow',
    );
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _isRunning = false);
        _onSessionCompleted();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _adjustMinutes(int delta) {
    if (_isRunning) return;
    final newMinutes = (_totalSeconds ~/ 60) + delta;
    if (newMinutes >= 5 && newMinutes <= 120) {
      setState(() {
        _totalSeconds = newMinutes * 60;
        _remainingSeconds = _totalSeconds;
      });
    }
  }

  void _onSessionCompleted() async {
    final app = Provider.of<AppProvider>(context, listen: false);
    final durationMins = _totalSeconds ~/ 60;
    final xp = await app.completeFocusSession(
      label: _labelController.text.trim(),
      durationMinutes: durationMins,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cyanHighlight.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.self_improvement, color: AppColors.cyanHighlight, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'Session Completed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'You maintained uninterrupted focus for $durationMins minutes.\n+$xp XP awarded to your mountain journey!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Finish & Return',
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = _totalSeconds > 0 ? (1.0 - (_remainingSeconds / _totalSeconds)) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Focus Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isRunning) {
              _pauseTimer();
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Session Label input
              TextField(
                controller: _labelController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'What are you focusing on?',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),

              const Spacer(),

              // Circular Countdown Timer
              Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyanHighlight),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _isRunning ? 'DEEP WORK IN PROGRESS' : 'READY TO START',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cyanHighlight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Duration Adjustment buttons (if not running)
              if (!_isRunning) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                      onPressed: () => _adjustMinutes(-5),
                    ),
                    Text(
                      '${_totalSeconds ~/ 60} mins',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                      onPressed: () => _adjustMinutes(5),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Controls: Start, Pause, Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_remainingSeconds < _totalSeconds) ...[
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.textMuted, size: 28),
                      onPressed: _resetTimer,
                    ),
                    const SizedBox(width: 20),
                  ],
                  GestureDetector(
                    onTap: _isRunning ? _pauseTimer : _startTimer,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
