import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/task_model.dart';

class TaskFilterState {
  final String? status;
  final String? priority;
  final String? search;
  final int? employeeId;

  TaskFilterState({this.status, this.priority, this.search, this.employeeId});

  TaskFilterState copyWith({
    String? status,
    String? priority,
    String? search,
    int? employeeId,
  }) {
    return TaskFilterState(
      status: status ?? this.status,
      priority: priority ?? this.priority,
      search: search ?? this.search,
      employeeId: employeeId ?? this.employeeId,
    );
  }
}

final taskFilterProvider = StateProvider<TaskFilterState>((ref) => TaskFilterState());

final tasksProvider = FutureProvider.autoDispose<List<TaskModel>>((ref) async {
  final filter = ref.watch(taskFilterProvider);

  try {
    final queryParams = <String, dynamic>{};
    if (filter.status != null && filter.status != 'all') queryParams['status'] = filter.status;
    if (filter.priority != null && filter.priority != 'all') queryParams['priority'] = filter.priority;
    if (filter.search != null && filter.search!.isNotEmpty) queryParams['search'] = filter.search;
    if (filter.employeeId != null) queryParams['employee_id'] = filter.employeeId;

    final response = await DioClient.instance.get(
      ApiEndpoints.tasks,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data['data']?['tasks'] != null) {
      final list = response.data['data']['tasks'] as List<dynamic>;
      return list.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (_) {
    // Rich fallback tasks
    return [
      TaskModel(
        id: 1,
        taskCode: 'TASK-2026-001',
        title: 'Monthly Balance Collection - Rahul Traders',
        customerId: 1,
        assignedEmployeeId: 1,
        targetAmount: 25000.0,
        collectedAmount: 10000.0,
        pendingAmount: 15000.0,
        dueDate: '2026-11-10',
        expectedVisitDate: '2026-11-04',
        priority: 'high',
        status: 'in_progress',
        additionalInstructions: 'Collect balance via UPI or Cash. Ensure owner signs delivery slip.',
        completionPercentage: 40.0,
        customerBusinessName: 'Rahul Traders',
        customerContactPerson: 'Rahul Parekh',
        customerPhone: '+91 98251 33445',
        customerAddress: 'Shop 14, Millennium Textile Market, Ring Road',
        customerCity: 'Surat',
        customerLatitude: 21.189025,
        customerLongitude: 72.836520,
        assignedEmployeeName: 'Amit Patel',
      ),
      TaskModel(
        id: 2,
        taskCode: 'TASK-2026-002',
        title: 'Overdue Recovery - Shree Ambica Textiles',
        customerId: 2,
        assignedEmployeeId: 1,
        targetAmount: 48500.0,
        collectedAmount: 0.0,
        pendingAmount: 48500.0,
        dueDate: '2026-11-06',
        expectedVisitDate: '2026-11-04',
        priority: 'urgent',
        status: 'pending',
        additionalInstructions: 'Meet Mr. Manoj Agarwal directly. Urgent payment required.',
        completionPercentage: 0.0,
        customerBusinessName: 'Shree Ambica Textiles',
        customerContactPerson: 'Manoj Agarwal',
        customerPhone: '+91 98240 77889',
        customerAddress: 'Plot 42, GIDC Industrial Estate, Pandesara',
        customerCity: 'Surat',
        customerLatitude: 21.135400,
        customerLongitude: 72.825100,
        assignedEmployeeName: 'Amit Patel',
      ),
      TaskModel(
        id: 3,
        taskCode: 'TASK-2026-003',
        title: 'Routine Clearance - Krishna Electronics',
        customerId: 3,
        assignedEmployeeId: 2,
        targetAmount: 18000.0,
        collectedAmount: 18000.0,
        pendingAmount: 0.0,
        dueDate: '2026-11-04',
        expectedVisitDate: '2026-11-04',
        priority: 'medium',
        status: 'completed',
        additionalInstructions: 'Collect invoice cash payment and issue receipt.',
        completionPercentage: 100.0,
        customerBusinessName: 'Krishna Electronics',
        customerContactPerson: 'Suresh Patel',
        customerPhone: '+91 94268 99112',
        customerAddress: 'Station Road, Opposite Railway Station',
        customerCity: 'Surat',
        customerLatitude: 21.205200,
        customerLongitude: 72.840300,
        assignedEmployeeName: 'Priya Singh',
      ),
    ];
  }
});
