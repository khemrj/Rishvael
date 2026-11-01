enum MessageStatus { sending, sent, failed }



class ChatMessage {
  const ChatMessage({
    required this.clientMsgId,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.id,
    this.status = MessageStatus.sent,
  });

  final String clientMsgId;
  final int? id; // server id; null while pending
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime createdAt;
  final MessageStatus status;

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
        clientMsgId: clientMsgId,
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        createdAt: createdAt,
        status: status ?? this.status,
      );

  /// Adjust keys here if your DTO differs.
  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] as num?)?.toInt();
    return ChatMessage(
      id: id,
      clientMsgId: (j['clientMsgId'] as String?) ?? 'srv-$id',
      conversationId: (j['conversationId'] as num).toInt(),
      senderId: (j['senderId'] as num).toInt(),
      content: (j['content'] ?? '') as String,
      createdAt:
          DateTime.tryParse('${j['createdAt']}')?.toLocal() ?? DateTime.now(),
      status: MessageStatus.sent,
    );
  }
}