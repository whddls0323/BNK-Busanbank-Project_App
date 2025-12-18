class ChatHistoryMessage {
  final int messageId;
  final String senderType; // USER/AGENT/SYSTEM
  final String message;
  final DateTime createdAt;

  ChatHistoryMessage({
    required this.messageId,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> j) {
    return ChatHistoryMessage(
      messageId: j['messageId'],
      senderType: (j['senderType'] ?? '').toString(),
      message: (j['message'] ?? '').toString(),
      createdAt: DateTime.parse(j['createdAt']),
    );
  }
}
