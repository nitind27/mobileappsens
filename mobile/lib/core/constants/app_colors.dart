import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (Enterprise Navy & Electric Blue)
  static const Color primary = Color(0xFF0F172A); // Deep Navy Slate
  static const Color primaryDark = Color(0xFF0A0F1D);
  static const Color primaryLight = Color(0xFF1E293B);

  static const Color electricBlue = Color(0xFF2563EB); // Vibrant Royal / Electric Blue
  static const Color electricBlueHover = Color(0xFF1D4ED8);
  static const Color skyBlue = Color(0xFF38BDF8);

  // Accent & Functional Status Colors
  static const Color success = Color(0xFF10B981); // Emerald Green (Collections, Check-in)
  static const Color successLight = Color(0xFFD1FAE5);
  
  static const Color warning = Color(0xFFF59E0B); // Amber (Pending, Late, Medium Priority)
  static const Color warningLight = Color(0xFFFEF3C7);
  
  static const Color danger = Color(0xFFEF4444); // Crimson / Coral Red (Overdue, Urgent, Stop)
  static const Color dangerLight = Color(0xFFFEE2E2);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);

  // Surfaces & Backgrounds (Light Mode)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardBorderLight = Color(0xFFE2E8F0);
  
  // Surfaces & Backgrounds (Dark Mode)
  static const Color backgroundDark = Color(0xFF0B1120);
  static const Color surfaceDark = Color(0xFF151E32);
  static const Color cardBorderDark = Color(0xFF1E293B);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
}
