enum ChatSessionStatus { active, ended }

class ChatSessionSummary {
  final int sessionId;
  final String inquiryType;
  final ChatSessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ChatSessionSummary({
    required this.sessionId,
    required this.inquiryType,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatSessionSummary.fromJson(Map<String, dynamic> j) {
    return ChatSessionSummary(
      sessionId: j['sessionId'],
      inquiryType: (j['inquiryType'] ?? '').toString(),
      status: ((j['status'] ?? 'ENDED').toString().toUpperCase() == 'ACTIVE')
          ? ChatSessionStatus.active
          : ChatSessionStatus.ended,
      startedAt: DateTime.parse(j['startedAt']),
      endedAt: j['endedAt'] == null ? null : DateTime.parse(j['endedAt']),
      lastMessage: j['lastMessage']?.toString(),
      lastMessageAt: j['lastMessageAt'] == null ? null : DateTime.parse(j['lastMessageAt']),
    );
  }
}