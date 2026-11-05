import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final String type; // 'priority', 'status', 'payment'

  const StatusBadge({
    super.key,
    required this.label,
    this.type = 'status',
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String display = label.replaceAll('_', ' ').toUpperCase();

    final norm = label.toLowerCase();

    if (norm == 'completed' || norm == 'verified' || norm == 'present' || norm == 'active') {
      bg = AppColors.successLight;
      fg = const Color(0xFF047857);
    } else if (norm == 'urgent' || norm == 'rejected' || norm == 'overdue' || norm == 'stopped') {
      bg = AppColors.dangerLight;
      fg = const Color(0xFFB91C1C);
    } else if (norm == 'high' || norm == 'in_progress' || norm == 'pending_verification' || norm == 'late') {
      bg = AppColors.warningLight;
      fg = const Color(0xFFB45309);
    } else if (norm == 'medium') {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
