class ChatMessage {
  final String id;
  final String conversationId;
  final String senderType; // 'user', 'bot', atau 'organizer'
  final String message;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.message,
    required this.createdAt,
    this.imageUrl,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      senderType: (json['sender_type'] ?? 'user').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      imageUrl: json['image_url']?.toString(),
      isRead: json['is_read'] == true,
    );
  }
}