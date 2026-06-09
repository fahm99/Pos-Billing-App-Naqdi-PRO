class ChatMessage {
  final String id;
  final String sessionId;
  final String content;
  final String role;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.content,
    required this.role,
    required this.timestamp,
  });
}
