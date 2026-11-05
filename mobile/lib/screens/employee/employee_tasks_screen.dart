import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/task_provider.dart';
import '../../widgets/status_badge.dart';
import 'record_payment_screen.dart';

class EmployeeTasksScreen extends ConsumerWidget {
  const EmployeeTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection Tasks'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No assigned tasks found.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(tasksProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, idx) {
                final task = tasks[idx];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              StatusBadge(label: task.priority, type: 'priority'),
                              const SizedBox(width: 8),
                              StatusBadge(label: task.status, type: 'status'),
                            ],
                          ),
                          Text(
                            'Due: ${DateFormatter.formatDisplay(task.dueDate)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        task.customerBusinessName ?? task.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${task.customerAddress ?? ""} • ${task.customerCity ?? ""}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      if (task.additionalInstructions != null && task.additionalInstructions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.electricBlue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.additionalInstructions!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMutedLight)),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(task.pendingAmount),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.danger),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (task.customerPhone != null)
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.phone, size: 18),
                                  onPressed: () => launchUrl(Uri.parse('tel:${task.customerPhone}')),
                                ),
                              const SizedBox(width: 8),
                              if (task.customerLatitude != null && task.customerLongitude != null)
                                IconButton.filledTonal(
                                  icon: const Icon(Icons.navigation_outlined, size: 18),
                                  onPressed: () {
                                    final url = 'google.navigation:q=${task.customerLatitude},${task.customerLongitude}';
                                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                  },
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.electricBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecordPaymentScreen(
                                        taskId: task.id,
                                        customerName: task.customerBusinessName ?? 'Client',
                                        pendingAmount: task.pendingAmount,
                                      ),
                                    ),
                                  ).then((_) => ref.refresh(tasksProvider));
                                },
                                child: const Text('Record'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
