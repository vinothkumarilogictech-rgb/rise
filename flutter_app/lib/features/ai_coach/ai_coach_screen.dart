import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/colors.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../timetable/timetable_review_screen.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _starters = [
    'Plan my day.',
    'Help me break down a goal.',
    'Review my weekly progress.',
    'I am struggling to stay consistent.',
    'Help me understand an engineering problem.',
  ];

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final app = Provider.of<AppProvider>(context, listen: false);
    if (app.isAiReplying || app.isUploadingTimetable) return;
    _messageController.clear();
    app.sendAiMessage(trimmed);
    _scrollToBottom();
  }

  Future<void> _pickAndUploadTimetable() async {
    final app = Provider.of<AppProvider>(context, listen: false);
    if (app.isUploadingTimetable || app.isAiReplying) return;

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      );

      if (file == null) return;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected file data.')),
        );
        return;
      }

      if (bytes.length > 15 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File exceeds 15MB limit. Please choose a smaller file.')),
        );
        return;
      }

      final extractRes = await app.uploadTimetableFile(
        fileBytes: bytes,
        filename: file.name,
      );

      if (!mounted) return;
      final committed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (ctx) => TimetableReviewScreen(extractResponse: extractRes),
        ),
      );

      if (committed == true && mounted) {
        app.sendAiMessage("I have scheduled my timetable from '${file.name}'. Please give me today's priority study focus.");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade700, content: Text('Timetable upload failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final history = app.aiChatHistory;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RISE AI Coach', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Conversational Assistant', style: TextStyle(fontSize: 10, color: AppColors.cyanHighlight)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Conversation Body
            Expanded(
              child: history.isEmpty
                  ? _buildEmptyCoachState(auth.user?.displayName ?? 'Climber')
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      itemBuilder: (ctx, idx) {
                        final msg = history[idx];
                        final isUser = msg['role'] == 'user';
                        return _buildMessageBubble(msg['content'] ?? '', isUser);
                      },
                    ),
            ),

            if (app.isAiReplying) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanHighlight),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'RISE AI Coach is generating a response...',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],

            if (app.isUploadingTimetable) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanHighlight),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Extracting schedule from timetable with Grok AI...',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyanHighlight),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Starters horizontal scroll
            if (history.isEmpty) ...[
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _starters.length,
                  itemBuilder: (ctx, idx) {
                    final starter = _starters[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(starter),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.cardBorder),
                        labelStyle: const TextStyle(fontSize: 12, color: AppColors.cyanHighlight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: (app.isAiReplying || app.isUploadingTimetable) ? null : () => _sendMessage(starter),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Composer bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.cyanHighlight),
                    tooltip: 'Upload Timetable (Image or PDF)',
                    onPressed: (app.isUploadingTimetable || app.isAiReplying)
                        ? null
                        : _pickAndUploadTimetable,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask a question, coding problem, or study plan...',
                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.elevatedCard,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (app.isAiReplying || app.isUploadingTimetable) ? null : _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: (app.isAiReplying || app.isUploadingTimetable) ? null : AppColors.primaryGradient,
                      color: (app.isAiReplying || app.isUploadingTimetable) ? AppColors.surface : null,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                        color: (app.isAiReplying || app.isUploadingTimetable) ? AppColors.textMuted : Colors.white,
                        size: 20,
                      ),
                      onPressed: (app.isAiReplying || app.isUploadingTimetable) ? null : () => _sendMessage(_messageController.text),
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

  Widget _buildEmptyCoachState(String name) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to climb, $name?',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'I am your dedicated mentor for GATE preparation, coding independence, and healthy consistency. Select a prompt below or type your current challenge.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryBlue : AppColors.elevatedCard,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
            bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isUser ? null : Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
