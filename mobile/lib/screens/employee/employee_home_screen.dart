import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';
import 'record_payment_screen.dart';

class EmployeeHomeScreen extends ConsumerWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(employeeDashboardProvider);
    final trackingState = ref.watch(locationTrackingProvider);
    final attendanceState = ref.watch(attendanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.fullName ?? "Field Agent"}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            Text(
              '${user?.designation ?? "Field Collection"} • ${user?.employeeCode ?? "EMP"}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_in_talk_outlined),
            tooltip: 'Call Manager',
            onPressed: () => context.push('/call/1?name=Rajesh%20Sharma&role=Admin'),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat with Admin',
            onPressed: () => context.push('/chat/1'),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (stats) {
          final progressRatio = stats.dailyTarget > 0 ? (stats.todayCollected / stats.dailyTarget).clamp(0.0, 1.0) : 0.0;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(employeeDashboardProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Target Hero Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "TODAY'S TARGET",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.skyBlue,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(stats.dailyTarget),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            // Circular Progress Ring
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 58,
                                  height: 58,
                                  child: CircularProgressIndicator(
                                    value: progressRatio,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white.withOpacity(0.15),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                  ),
                                ),
                                Text(
                                  '${(progressRatio * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('COLLECTED TODAY', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(stats.todayCollected),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('REMAINING PENDING', style: TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(stats.todayPending),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Action Work Controls
                  Row(
                    children: [
                      // Attendance Check In / Out
                      Expanded(
                        child: CustomButton(
                          text: attendanceState.isCheckedIn ? 'Checked In' : 'Punch In',
                          icon: Icons.fingerprint,
                          backgroundColor: attendanceState.isCheckedIn ? AppColors.success : AppColors.electricBlue,
                          height: 48,
                          onPressed: () {
                            if (!attendanceState.isCheckedIn) {
                              ref.read(attendanceProvider.notifier).checkIn();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You are already checked in for today.')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Location Sharing Consent Toggle
                      Expanded(
                        child: CustomButton(
                          text: trackingState.isTrackingActive ? 'Tracking On' : 'Start Route',
                          icon: Icons.my_location,
                          backgroundColor: trackingState.isTrackingActive ? AppColors.success : const Color(0xFF334155),
                          height: 48,
                          onPressed: () {
                            if (!trackingState.isTrackingActive) {
                              ref.read(locationTrackingProvider.notifier).startTrackingWithConsent();
                            } else {
                              ref.read(locationTrackingProvider.notifier).stopTracking();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Assigned Customer Visits Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Visit Schedule",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${stats.todayVisits.length} Visits',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (stats.todayVisits.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('No pending visits scheduled for today!'),
                      ),
                    ),
                  ] else ...[
                    ...stats.todayVisits.map((visit) {
                      final targetAmt = double.tryParse(visit['target_amount']?.toString() ?? '0') ?? 0.0;
                      final pendingAmt = double.tryParse(visit['pending_amount']?.toString() ?? '0') ?? 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge(label: visit['priority'] ?? 'medium', type: 'priority'),
                                Text(
                                  visit['task_code'] ?? '',
                                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              visit['business_name'] ?? 'Client Business',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact: ${visit['contact_person'] ?? ""}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              visit['address'] ?? '',
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Target: ${CurrencyFormatter.format(targetAmt)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                Text(
                                  'Pending: ${CurrencyFormatter.format(pendingAmt)}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.danger),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            // Action Buttons: Call, Map Navigation, Record Collection
                            Row(
                              children: [
                                if (visit['phone'] != null)
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.phone, size: 18),
                                    onPressed: () => launchUrl(Uri.parse('tel:${visit['phone']}')),
                                  ),
                                const SizedBox(width: 8),
                                if (visit['latitude'] != null && visit['longitude'] != null)
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.navigation_outlined, size: 18),
                                    onPressed: () {
                                      final url = 'google.navigation:q=${visit['latitude']},${visit['longitude']}';
                                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                    },
                                  ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('Collect Payment'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RecordPaymentScreen(
                                          taskId: visit['task_id'] ?? 1,
                                          customerName: visit['business_name'] ?? 'Client',
                                          pendingAmount: pendingAmt,
                                        ),
                                      ),
                                    ).then((_) => ref.refresh(employeeDashboardProvider));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
