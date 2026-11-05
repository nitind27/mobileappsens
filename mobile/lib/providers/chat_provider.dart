import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/message_model.dart';

class ChatState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final int contactUserId;

  ChatNotifier(this.contactUserId) : super(ChatState(isLoading: true)) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      final res = await DioClient.instance.get(ApiEndpoints.chatMessages(contactUserId));
      if (res.statusCode == 200 && res.data['data']?['messages'] != null) {
        final list = res.data['data']['messages'] as List<dynamic>;
        state = state.copyWith(
          messages: list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList(),
          isLoading: false,
        );
        return;
      }
    } catch (_) {}

    // Fallback demo conversation
    state = state.copyWith(
      messages: [
        MessageModel(
          id: 1,
          senderId: 1,
          receiverId: 2,
          messageType: 'text',
          content: 'Hi Amit, please visit Rahul Traders first today as they promised settlement before noon.',
          isRead: true,
          createdAt: '10:00 AM',
          senderName: 'Rajesh Sharma (Admin)',
        ),
        MessageModel(
          id: 2,
          senderId: 2,
          receiverId: 1,
          messageType: 'text',
          content: 'Understood sir. I have reached the market and collected ₹10,000 UPI advance.',
          isRead: true,
          createdAt: '11:32 AM',
          senderName: 'Amit Patel',
        ),
        MessageModel(
          id: 3,
          senderId: 2,
          receiverId: 1,
          messageType: 'audio',
          content: 'Audio note: Remaining balance settlement notes.',
          durationSeconds: 14,
          isRead: false,
          createdAt: '11:35 AM',
          senderName: 'Amit Patel',
        ),
      ],
      isLoading: false,
    );
  }

  Future<void> sendMessage(String text, {String type = 'text', int durationSeconds = 0}) async {
    final newMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: 2,
      receiverId: contactUserId,
      messageType: type,
      content: text,
      durationSeconds: durationSeconds,
      isRead: false,
      createdAt: 'Just now',
      senderName: 'Me',
    );

    state = state.copyWith(messages: [...state.messages, newMsg]);

    try {
      await DioClient.instance.post(
        ApiEndpoints.sendMessage,
        data: {
          'receiver_id': contactUserId,
          'message_type': type,
          'content': text,
          'duration_seconds': durationSeconds,
        },
      );
    } catch (_) {}
  }
}

final chatProviderFamily = StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, userId) {
  return ChatNotifier(userId);
});
