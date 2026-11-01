class Conversation {
  final int conversationId;
  final int receiverId;
  final String receiverUsername;
  final String? receiverProfilePictureUrl;
  final String? lastMessage;
  final int? lastMessageSenderId;
  final DateTime? lastMessageAt;

  Conversation({
    required this.conversationId,
    required this.receiverId,
    required this.receiverUsername,
    this.receiverProfilePictureUrl,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] ?? 0,
      receiverId: json['receiverId'] ?? 0,
      receiverUsername: json['receiverUsername'] ?? '',
      receiverProfilePictureUrl: json['receiverProfilePictureUrl'],
      lastMessage: json['lastMessage'],
      lastMessageSenderId: json['lastMessageSenderId'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
    );
  }
}