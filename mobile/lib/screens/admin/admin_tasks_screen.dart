import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/task_provider.dart';
import '../../widgets/status_badge.dart';
import 'create_task_screen.dart';

class AdminTasksScreen extends ConsumerWidget {
  const AdminTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final filter = ref.watch(taskFilterProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Collection Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Create Assignment',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
              ).then((_) => ref.refresh(tasksProvider));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by client, task ID, city...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: filter.search?.isNotEmpty == true
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          ref.read(taskFilterProvider.notifier).state = filter.copyWith(search: '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(taskFilterProvider.notifier).state = filter.copyWith(search: val);
              },
            ),
          ),

          // Horizontal Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildFilterChip(context, ref, 'All', null),
                _buildFilterChip(context, ref, 'Pending', 'pending'),
                _buildFilterChip(context, ref, 'In Progress', 'in_progress'),
                _buildFilterChip(context, ref, 'Completed', 'completed'),
              ],
            ),
          ),
          const Divider(height: 12),

          // Task List
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 48, color: AppColors.textMutedLight),
                        SizedBox(height: 12),
                        Text('No collection tasks match this filter', style: TextStyle(color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(tasksProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                                  task.taskCode,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              task.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.storefront_outlined, size: 16, color: AppColors.textSecondaryLight),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${task.customerBusinessName ?? "Customer"} • ${task.customerCity ?? ""}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondaryLight),
                                const SizedBox(width: 6),
                                Text(
                                  'Assigned to: ${task.assignedEmployeeName ?? "Agent"}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('TARGET AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMutedLight)),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.format(task.targetAmount),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.electricBlue),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('DUE DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMutedLight)),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormatter.formatDisplay(task.dueDate),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, String? value) {
    final current = ref.watch(taskFilterProvider).status;
    final isSelected = current == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          ref.read(taskFilterProvider.notifier).state = ref.read(taskFilterProvider).copyWith(status: value);
        },
      ),
    );
  }
}
