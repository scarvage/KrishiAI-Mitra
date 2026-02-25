class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isVoice;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.isVoice = false,
  }) : timestamp = timestamp ?? DateTime.now();

  String getFormattedTime() {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
