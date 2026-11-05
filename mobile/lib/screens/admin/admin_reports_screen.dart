import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/dashboard_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Audit Center'),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Financial Summary',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatColumn('TOTAL TARGET', CurrencyFormatter.compact(stats.totalTarget), AppColors.primaryLight),
                          _buildStatColumn('TOTAL COLLECTED', CurrencyFormatter.compact(stats.totalCollected), AppColors.success),
                          _buildStatColumn('PENDING', CurrencyFormatter.compact(stats.totalPending), AppColors.danger),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Audit Log & Compliance Section
                const Text(
                  'Recent Security & Audit Logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'All administrative actions, location tracking consents, and verifications are cryptographically tracked.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: Column(
                    children: [
                      _buildAuditTile('LOCATION_SHARING_STARTED', 'Amit Patel granted live GPS tracking consent', 'Today, 09:10 AM', Icons.gps_fixed),
                      const Divider(height: 1),
                      _buildAuditTile('VERIFY_PAYMENT', 'Rajesh Sharma approved ₹10,000 for TXN-8801', 'Today, 11:45 AM', Icons.verified_user),
                      const Divider(height: 1),
                      _buildAuditTile('TASK_CREATED', 'New assignment TASK-2026-001 assigned to Amit Patel', 'Today, 09:00 AM', Icons.assignment),
                      const Divider(height: 1),
                      _buildAuditTile('ATTENDANCE_CHECKIN', 'Priya Singh checked in with GPS verification', 'Today, 08:58 AM', Icons.fingerprint),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMutedLight)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildAuditTile(String action, String details, String time, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.electricBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.electricBlue),
      ),
      title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(details, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
      trailing: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
    );
  }
}
