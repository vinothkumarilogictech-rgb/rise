import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/timetable_model.dart';
import '../../providers/app_provider.dart';

class TimetableReviewScreen extends StatefulWidget {
  final TimetableExtractResponseModel extractResponse;

  const TimetableReviewScreen({super.key, required this.extractResponse});

  @override
  State<TimetableReviewScreen> createState() => _TimetableReviewScreenState();
}

class _TimetableReviewScreenState extends State<TimetableReviewScreen> {
  late List<TimetableSessionItemModel> _sessions;
  bool _skipDuplicates = true;
  bool _replaceUncompleted = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sessions = List.from(widget.extractResponse.sessions);
  }

  int get _selectedCount => _sessions.where((s) => s.isSelected).length;

  void _toggleSelectAll(bool select) {
    setState(() {
      for (var s in _sessions) {
        s.isSelected = select;
      }
    });
  }

  void _removeSession(int index) {
    setState(() {
      _sessions.removeAt(index);
    });
  }

  Future<void> _editSession(int index) async {
    final session = _sessions[index];
    final dateCtrl = TextEditingController(text: session.date);
    final startCtrl = TextEditingController(text: session.startTime);
    final endCtrl = TextEditingController(text: session.endTime);
    final subjectCtrl = TextEditingController(text: session.subject);
    final topicCtrl = TextEditingController(text: session.topic);
    String priority = session.priority;
    String sessionType = session.sessionType;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.elevatedCard,
          title: const Text('Edit Study Session', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', labelStyle: TextStyle(color: AppColors.cyanHighlight)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(labelText: 'Start Time', labelStyle: TextStyle(color: AppColors.cyanHighlight)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(labelText: 'End Time', labelStyle: TextStyle(color: AppColors.cyanHighlight)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject', labelStyle: TextStyle(color: AppColors.cyanHighlight)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(labelText: 'Topic / Objective', labelStyle: TextStyle(color: AppColors.cyanHighlight)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Priority: ', style: TextStyle(color: AppColors.textSecondary)),
                    DropdownButton<String>(
                      dropdownColor: AppColors.elevatedCard,
                      value: priority,
                      items: const [
                        DropdownMenuItem(value: 'high', child: Text('High', style: TextStyle(color: Colors.orangeAccent))),
                        DropdownMenuItem(value: 'medium', child: Text('Medium', style: TextStyle(color: AppColors.cyanHighlight))),
                        DropdownMenuItem(value: 'low', child: Text('Low', style: TextStyle(color: Colors.white70))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => priority = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (updated == true) {
      setState(() {
        session.date = dateCtrl.text.trim();
        session.startTime = startCtrl.text.trim();
        session.endTime = endCtrl.text.trim();
        session.subject = subjectCtrl.text.trim();
        session.topic = topicCtrl.text.trim();
        session.priority = priority;
        session.sessionType = sessionType;
      });
    }
  }

  Future<void> _commitSchedule() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one session to add.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final app = Provider.of<AppProvider>(context, listen: false);

    try {
      final res = await app.commitTimetableSessions(
        _sessions,
        skipDuplicates: _skipDuplicates,
        replaceUncompleted: _replaceUncompleted,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(res['message'] ?? 'Successfully added timetable schedule to RISE!'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade700, content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Extracted Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all, color: AppColors.cyanHighlight),
            tooltip: 'Select All',
            onPressed: () => _toggleSelectAll(true),
          ),
          IconButton(
            icon: const Icon(Icons.deselect, color: AppColors.textMuted),
            tooltip: 'Deselect All',
            onPressed: () => _toggleSelectAll(false),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header summary banner
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryBlue.withOpacity(0.2), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.white, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.extractResponse.filename} (${_sessions.length} Sessions)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_selectedCount of ${_sessions.length} sessions selected for import',
                          style: const TextStyle(color: AppColors.cyanHighlight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Duplicate Handling Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _skipDuplicates ? 'Skip existing duplicates' : 'Allow duplicate tasks',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ),
                    Switch(
                      value: _skipDuplicates,
                      activeColor: AppColors.cyanHighlight,
                      onChanged: (val) => setState(() => _skipDuplicates = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // List of Sessions
            Expanded(
              child: _sessions.isEmpty
                  ? const Center(
                      child: Text('No sessions available.', style: TextStyle(color: AppColors.textMuted)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sessions.length,
                      itemBuilder: (ctx, idx) {
                        final session = _sessions[idx];
                        return _buildSessionCard(session, idx);
                      },
                    ),
            ),

            // Commit Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (_isSaving || _selectedCount == 0) ? null : _commitSchedule,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Adding Schedule...' : 'Add Schedule to RISE ($_selectedCount Tasks)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(TimetableSessionItemModel session, int index) {
    Color priorityColor = session.priority == 'high'
        ? Colors.orangeAccent
        : (session.priority == 'medium' ? AppColors.cyanHighlight : Colors.white70);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: session.isSelected ? AppColors.elevatedCard : AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: session.isSelected ? AppColors.cardBorder : AppColors.cardBorder.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: session.isSelected,
              activeColor: AppColors.primaryBlue,
              checkColor: Colors.white,
              onChanged: (val) => setState(() => session.isSelected = val ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Time Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${session.date} ${session.weekday ?? ''}'.trim(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${session.startTime} - ${session.endTime}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Subject and Topic
                  Text(
                    session.subject,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session.topic,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // Session Type & Priority Chips
                  Wrap(
                    spacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: priorityColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          session.priority.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          session.sessionType.toUpperCase(),
                          style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                        ),
                      ),
                      Text(
                        '${session.estimatedMinutes} mins',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: AppColors.cyanHighlight),
                  onPressed: () => _editSession(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  onPressed: () => _removeSession(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
