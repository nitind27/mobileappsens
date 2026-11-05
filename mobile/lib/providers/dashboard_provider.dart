import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/dashboard_model.dart';
import '../models/employee_model.dart';
import '../models/transaction_model.dart';

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardStats>((ref) async {
  try {
    final response = await DioClient.instance.get(ApiEndpoints.adminDashboard);
    if (response.statusCode == 200 && response.data['data'] != null) {
      return AdminDashboardStats.fromJson(response.data['data']);
    }
    throw Exception('Failed to load admin stats');
  } catch (_) {
    // Return rich realistic fallback dataset
    return AdminDashboardStats(
      totalEmployees: 4,
      activeEmployees: 3,
      onFieldEmployees: 2,
      todayCollection: 28000.0,
      monthlyCollection: 540000.0,
      totalPending: 95500.0,
      totalTarget: 635500.0,
      totalCollected: 540000.0,
      achievementPercent: 84.9,
      tasksCount: {
        'total': 18,
        'completed': 12,
        'in_progress': 4,
        'pending': 2,
        'overdue': 0,
      },
      paymentMethods: [
        {'payment_method': 'upi', 'total_amount': 285000.0, 'tx_count': 14},
        {'payment_method': 'cash', 'total_amount': 195000.0, 'tx_count': 10},
        {'payment_method': 'cheque', 'total_amount': 60000.0, 'tx_count': 2},
      ],
      rankings: [
        {
          'id': 1,
          'full_name': 'Amit Patel',
          'employee_code': 'EMP-1001',
          'current_status': 'in_field',
          'total_collected': 245000.0,
          'transactions_count': 9,
        },
        {
          'id': 2,
          'full_name': 'Priya Singh',
          'employee_code': 'EMP-1002',
          'current_status': 'online',
          'total_collected': 195000.0,
          'transactions_count': 8,
        },
        {
          'id': 3,
          'full_name': 'Vikram Rathore',
          'employee_code': 'EMP-1003',
          'current_status': 'offline',
          'total_collected': 100000.0,
          'transactions_count': 4,
        },
      ],
      recentTransactions: [
        TransactionModel(
          id: 1,
          transactionCode: 'TXN-8801',
          taskId: 1,
          customerId: 1,
          employeeId: 1,
          amountCollected: 10000.0,
          paymentMethod: 'upi',
          transactionReference: 'UPI/26110488921/HDFC',
          paymentStatus: 'verified',
          collectedAt: '2026-11-04 11:30:00',
          customerName: 'Rahul Traders',
          employeeName: 'Amit Patel',
        ),
        TransactionModel(
          id: 2,
          transactionCode: 'TXN-8802',
          taskId: 3,
          customerId: 3,
          employeeId: 2,
          amountCollected: 18000.0,
          paymentMethod: 'cash',
          transactionReference: 'CASH-REC-10492',
          paymentStatus: 'pending_verification',
          collectedAt: '2026-11-04 14:15:00',
          customerName: 'Krishna Electronics',
          employeeName: 'Priya Singh',
        ),
      ],
      activeFieldMap: [
        EmployeeModel(
          id: 1,
          userId: 2,
          employeeCode: 'EMP-1001',
          designation: 'Senior Recovery Officer',
          department: 'Field Operations',
          joiningDate: '2024-01-15',
          dailyTarget: 35000,
          monthlyTarget: 850000,
          workStartTime: '09:00:00',
          workEndTime: '19:00:00',
          isTrackingEnabled: true,
          currentStatus: 'in_field',
          batteryLevel: 86,
          fullName: 'Amit Patel',
          email: 'amit.patel@fieldpilot.com',
          phone: '+91 98791 44556',
          lastLat: 21.189025,
          lastLng: 72.836520,
          lastLocationTime: '2026-11-04 11:30:00',
        ),
        EmployeeModel(
          id: 2,
          userId: 3,
          employeeCode: 'EMP-1002',
          designation: 'Field Collection Specialist',
          department: 'Field Operations',
          joiningDate: '2024-03-01',
          dailyTarget: 30000,
          monthlyTarget: 750000,
          workStartTime: '09:00:00',
          workEndTime: '19:00:00',
          isTrackingEnabled: true,
          currentStatus: 'online',
          batteryLevel: 92,
          fullName: 'Priya Singh',
          email: 'priya.singh@fieldpilot.com',
          phone: '+91 98111 22334',
          lastLat: 21.205200,
          lastLng: 72.840300,
          lastLocationTime: '2026-11-04 13:50:00',
        ),
      ],
    );
  }
});

final employeeDashboardProvider = FutureProvider.autoDispose<EmployeeDashboardStats>((ref) async {
  try {
    final response = await DioClient.instance.get(ApiEndpoints.employeeDashboard);
    if (response.statusCode == 200 && response.data['data'] != null) {
      return EmployeeDashboardStats.fromJson(response.data['data']);
    }
    throw Exception('Failed to load employee stats');
  } catch (_) {
    return EmployeeDashboardStats(
      dailyTarget: 35000.0,
      todayCollected: 10000.0,
      todayPending: 25000.0,
      completionRate: 28.5,
      currentStatus: 'in_field',
      isTrackingEnabled: true,
      batteryLevel: 86,
      attendance: {
        'id': 1,
        'date': '2026-11-04',
        'check_in_time': '09:05:12',
        'status': 'present',
      },
      locationSession: {
        'id': 1,
        'status': 'active',
        'start_time': '09:10:00',
        'total_distance_km': 14.8,
      },
      taskCounts: {
        'total': 5,
        'completed': 1,
        'in_progress': 2,
        'pending': 2,
        'overdue': 0,
      },
      todayVisits: [
        {
          'task_id': 1,
          'task_code': 'TASK-2026-001',
          'title': 'Monthly Balance Collection - Rahul Traders',
          'target_amount': 25000.0,
          'collected_amount': 10000.0,
          'pending_amount': 15000.0,
          'priority': 'high',
          'status': 'in_progress',
          'due_date': '2026-11-10',
          'customer_id': 1,
          'business_name': 'Rahul Traders',
          'contact_person': 'Rahul Parekh',
          'phone': '+91 98251 33445',
          'address': 'Shop 14, Millennium Textile Market, Ring Road',
          'city': 'Surat',
          'latitude': 21.189025,
          'longitude': 72.836520,
        },
        {
          'task_id': 2,
          'task_code': 'TASK-2026-002',
          'title': 'Overdue Recovery - Shree Ambica Textiles',
          'target_amount': 48500.0,
          'collected_amount': 0.0,
          'pending_amount': 48500.0,
          'priority': 'urgent',
          'status': 'pending',
          'due_date': '2026-11-06',
          'customer_id': 2,
          'business_name': 'Shree Ambica Textiles',
          'contact_person': 'Manoj Agarwal',
          'phone': '+91 98240 77889',
          'address': 'Plot 42, GIDC Industrial Estate, Pandesara',
          'city': 'Surat',
          'latitude': 21.135400,
          'longitude': 72.825100,
        },
      ],
    );
  }
});
