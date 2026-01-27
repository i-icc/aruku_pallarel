class WalkChatMessage {
  const WalkChatMessage({
    required this.chatId,
    required this.senderType,
    required this.message,
    this.url,
    this.suggestId,
    this.createdAt,
  });

  final String chatId;
  final String senderType;
  final String message;
  final String? url;
  final String? suggestId;
  final DateTime? createdAt;

  bool get isSystem => senderType == 'system';
}
