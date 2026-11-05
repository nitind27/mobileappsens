class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String messageType; // 'text', 'audio', 'image'
  final String? content;
  final String? mediaUrl;
  final int durationSeconds;
  final bool isRead;
  final String createdAt;
  final String? senderName;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    this.content,
    this.mediaUrl,
    this.durationSeconds = 0,
    required this.isRead,
    required this.createdAt,
    this.senderName,
  });

  bool get isAudio => messageType == 'audio';
  bool get isText => messageType == 'text';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      senderId: int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      receiverId: int.tryParse(json['receiver_id']?.toString() ?? '0') ?? 0,
      messageType: json['message_type']?.toString() ?? 'text',
      content: json['content']?.toString(),
      mediaUrl: json['media_url']?.toString(),
      durationSeconds: int.tryParse(json['duration_seconds']?.toString() ?? '0') ?? 0,
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      senderName: json['sender_name']?.toString(),
    );
  }
}
