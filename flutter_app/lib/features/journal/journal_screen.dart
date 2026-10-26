import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../providers/app_provider.dart';
import '../../shared/widgets/custom_buttons.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedMood = 'focused';

  final List<String> _moods = ['focused', 'grateful', 'motivated', 'calm', 'tired'];

  final List<String> _prompts = [
    'What did I accomplish today?',
    'What engineering or coding concept did I deepen?',
    'What was difficult and how will I adapt?',
    'What is my single next small step for tomorrow?',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntryForDate(_selectedDate);
  }

  void _loadEntryForDate(DateTime date) {
    final app = Provider.of<AppProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final existing = app.journalEntries.where((e) => e.date == dateStr).toList();
    if (existing.isNotEmpty) {
      _contentController.text = existing.first.content;
      _selectedMood = existing.first.mood;
    } else {
      _contentController.clear();
      _selectedMood = 'focused';
    }
  }

  void _insertPrompt(String prompt) {
    final current = _contentController.text;
    final addition = '\n**$prompt**\n';
    _contentController.text = current.isEmpty ? addition.trimLeft() : '$current$addition';
  }

  void _saveEntry() async {
    final text = _contentController.text.trim();
    if (text.isEmpty) return;

    final app = Provider.of<AppProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final xp = await app.saveJournalEntry(
      date: dateStr,
      content: text,
      mood: _selectedMood,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(xp > 0 ? 'Reflection saved! +$xp XP awarded.' : 'Reflection saved successfully.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final dateStr = DateFormat('EEEE, MMM d').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Reflection Journal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.cyanHighlight),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          _loadEntryForDate(_selectedDate);
                        });
                      },
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                          _loadEntryForDate(_selectedDate);
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Mood selector
              const Text(
                'How are you feeling tonight?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _moods.map((mood) {
                    final isSelected = _selectedMood == mood;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(mood[0].toUpperCase() + mood.substring(1)),
                        selected: isSelected,
                        selectedColor: AppColors.primaryBlue,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (_) => setState(() => _selectedMood = mood),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              // Prompts assistant
              const Text(
                'Reflection Prompts (Tap to insert):',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _prompts.map((p) {
                  return ActionChip(
                    label: Text(p),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.cardBorder),
                    labelStyle: const TextStyle(fontSize: 11, color: AppColors.cyanHighlight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: () => _insertPrompt(p),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // Reflection Text Area
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: 10,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'Record today\'s breakthroughs, lessons, and tomorrow\'s small step...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              GradientButton(
                text: 'Save Today\'s Reflection',
                icon: Icons.check,
                onPressed: _saveEntry,
              ),

              const SizedBox(height: 24),

              // Previous Reflections List
              if (app.journalEntries.isNotEmpty) ...[
                const Text(
                  'Past Reflections',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                ...app.journalEntries.map((entry) {
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
                            Text(
                              entry.date,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.elevatedCard,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.mood.toUpperCase(),
                                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
