import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';

class CollectionProgressBar extends StatelessWidget {
  final double collected;
  final double target;
  final double percentage;

  const CollectionProgressBar({
    super.key,
    required this.collected,
    required this.target,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = (target > 0) ? (collected / target).clamp(0.0, 1.0) : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievement: ${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.electricBlue,
              ),
            ),
            Text(
              '${CurrencyFormatter.format(collected)} / ${CurrencyFormatter.format(target)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: clampedRatio,
            minHeight: 10,
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              clampedRatio >= 1.0 ? AppColors.success : AppColors.electricBlue,
            ),
          ),
        ),
      ],
    );
  }
}
