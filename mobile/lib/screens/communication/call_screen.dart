import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CallScreen extends StatefulWidget {
  final int userId;
  final String userName;
  final String callType; // 'audio' or 'video'

  const CallScreen({
    super.key,
    required this.userId,
    this.userName = 'Contact',
    this.callType = 'audio',
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  bool _isCallAccepted = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isVideoEnabled = true;
  int _callDurationSeconds = 0;
  Timer? _callTimer;

  @override
  void initState() {
    super.initState();
    // Simulate auto-connecting or ready state after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCallAccepted = true;
          _startDurationTimer();
        });
      }
    });
  }

  void _startDurationTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _callDurationSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callType == 'video';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Video background / Avatar
            if (isVideo && _isCallAccepted && _isVideoEnabled)
              Container(
                color: const Color(0xFF1E293B),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam, size: 72, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        'Secure WebRTC Video Feed Active',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.electricBlue.withOpacity(0.2),
                      child: Text(
                        widget.userName[0],
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.userName,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCallAccepted
                          ? _formatDuration(_callDurationSeconds)
                          : 'Calling...',
                      style: const TextStyle(color: AppColors.skyBlue, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: AppColors.success),
                          SizedBox(width: 6),
                          Text(
                            'End-to-End Encrypted',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Top Status Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.callType.toUpperCase() + ' CALL',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),

            // Bottom In-Call Controls
            Positioned(
              bottom: 36,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Mic
                  _buildControlBtn(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    isActive: _isMuted,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onTap: () => setState(() => _isMuted = !_isMuted),
                  ),
                  // Speaker
                  _buildControlBtn(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    isActive: _isSpeakerOn,
                    label: 'Speaker',
                    onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                  ),
                  // Video Toggle (if video call)
                  if (isVideo)
                    _buildControlBtn(
                      icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      isActive: !_isVideoEnabled,
                      label: 'Video',
                      onTap: () => setState(() => _isVideoEnabled = !_isVideoEnabled),
                    ),
                  // End Call Button
                  FloatingActionButton(
                    heroTag: 'end_call_fab',
                    backgroundColor: AppColors.danger,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required bool isActive,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: Icon(icon, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: isActive ? Colors.white : Colors.white24,
            foregroundColor: isActive ? AppColors.primary : Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: onTap,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
