class ChatThread {
  final String id;
  final String title;
  final String? lastMessage;
  final DateTime? updatedAt;
  final bool hasUnread;

  const ChatThread({
    required this.id,
    required this.title,
    this.lastMessage,
    this.updatedAt,
    this.hasUnread = false,
  });
}

class ChatMessage {
  final String id;
  final String chatId;
  final String text;
  final String senderId;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.text,
    required this.senderId,
    required this.createdAt,
  });
}
