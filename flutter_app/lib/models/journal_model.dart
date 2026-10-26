class JournalEntryModel {
  final String id;
  final String date;
  final String content;
  final String? promptsAnswered;
  final String mood;
  final String? imageUrl;
  final DateTime updatedAt;

  JournalEntryModel({
    required this.id,
    required this.date,
    required this.content,
    this.promptsAnswered,
    this.mood = 'focused',
    this.imageUrl,
    required this.updatedAt,
  });

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) {
    return JournalEntryModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      content: json['content'] ?? '',
      promptsAnswered: json['prompts_answered'],
      mood: json['mood'] ?? 'focused',
      imageUrl: json['image_url'],
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
