import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';

class EmployeeProfileScreen extends ConsumerWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final attendanceState = ref.watch(attendanceProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Attendance'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Employee Identity Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.electricBlue.withOpacity(0.15),
                    child: Text(
                      user?.fullName.isNotEmpty == true ? user!.fullName[0] : 'E',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.electricBlue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Amit Patel',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user?.designation ?? "Field Collection"} • ${user?.employeeCode ?? "EMP-1001"}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? '+91 98791 44556',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Today's Work Shift & Punch Out Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Today Shift Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHECK IN TIME', style: TextStyle(fontSize: 10, color: AppColors.textMutedLight, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(attendanceState.todayRecord?.checkInTime ?? '09:05 AM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      StatusBadge(label: attendanceState.todayRecord?.status ?? 'present'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: attendanceState.isCheckedOut ? 'Shift Ended (Checked Out)' : 'End Shift (Check Out)',
                    icon: Icons.exit_to_app,
                    backgroundColor: attendanceState.isCheckedOut ? AppColors.textMutedLight : AppColors.danger,
                    onPressed: attendanceState.isCheckedOut
                        ? null
                        : () => ref.read(attendanceProvider.notifier).checkOut(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Attendance Log History
            const Text('Recent Attendance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),

            historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load attendance history'),
              data: (records) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final item = records[idx];
                      return ListTile(
                        leading: const Icon(Icons.date_range, color: AppColors.electricBlue),
                        title: Text(item.date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('In: ${item.checkInTime} • Out: ${item.checkOutTime ?? "-"}'),
                        trailing: StatusBadge(label: item.status),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            CustomButton(
              text: 'Sign Out',
              isOutlined: true,
              backgroundColor: AppColors.danger,
              textColor: AppColors.danger,
              icon: Icons.logout,
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
