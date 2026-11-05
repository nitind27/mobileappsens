import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int contactUserId;

  const ChatScreen({super.key, required this.contactUserId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  bool _isRecordingVoice = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProviderFamily(widget.contactUserId).notifier).sendMessage(text);
    _messageController.clear();
  }

  void _sendVoiceNote() {
    setState(() => _isRecordingVoice = true);

    // Simulate 5s voice note recording
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isRecordingVoice = false);
        ref.read(chatProviderFamily(widget.contactUserId).notifier).sendMessage(
              'Voice note regarding task visit update.',
              type: 'audio',
              durationSeconds: 12,
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice note recorded and sent.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProviderFamily(widget.contactUserId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contactUserId == 1 ? 'Rajesh Sharma (Admin)' : 'Amit Patel (Agent)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text('Online • Dispatch Operations', style: TextStyle(fontSize: 11, color: AppColors.success)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Voice Call',
            onPressed: () {
              context.push('/call/${widget.contactUserId}?type=audio&name=${widget.contactUserId == 1 ? "Rajesh Sharma" : "Amit Patel"}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Video Call',
            onPressed: () {
              context.push('/call/${widget.contactUserId}?type=video&name=${widget.contactUserId == 1 ? "Rajesh Sharma" : "Amit Patel"}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages thread
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (ctx, idx) {
                      final msg = chatState.messages[idx];
                      final isMe = msg.senderName == 'Me' || msg.senderId == 2;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.electricBlue
                                : (isDark ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
                              bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
                            ),
                            border: isMe ? null : Border.all(color: AppColors.cardBorderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg.isAudio) ...[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.play_circle_fill, color: isMe ? Colors.white : AppColors.electricBlue, size: 28),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Voice Note (${msg.durationSeconds}s)',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  msg.content ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : (isDark ? Colors.white : AppColors.textPrimaryLight),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  msg.createdAt,
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : AppColors.textMutedLight,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isRecordingVoice ? Icons.mic : Icons.mic_none, color: _isRecordingVoice ? AppColors.danger : AppColors.electricBlue),
                  tooltip: 'Record Task Voice Note',
                  onPressed: _sendVoiceNote,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type field message or update...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.electricBlue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
