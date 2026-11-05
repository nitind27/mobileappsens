import 'employee_model.dart';
import 'transaction_model.dart';

class AdminDashboardStats {
  final int totalEmployees;
  final int activeEmployees;
  final int onFieldEmployees;
  final double todayCollection;
  final double monthlyCollection;
  final double totalPending;
  final double totalTarget;
  final double totalCollected;
  final double achievementPercent;
  final Map<String, int> tasksCount;
  final List<Map<String, dynamic>> paymentMethods;
  final List<Map<String, dynamic>> rankings;
  final List<TransactionModel> recentTransactions;
  final List<EmployeeModel> activeFieldMap;

  AdminDashboardStats({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.onFieldEmployees,
    required this.todayCollection,
    required this.monthlyCollection,
    required this.totalPending,
    required this.totalTarget,
    required this.totalCollected,
    required this.achievementPercent,
    required this.tasksCount,
    required this.paymentMethods,
    required this.rankings,
    required this.recentTransactions,
    required this.activeFieldMap,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final tasksMap = (summary['tasks_count'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, int.tryParse(v.toString()) ?? 0),
    );

    final txList = (json['recent_transactions'] as List<dynamic>? ?? [])
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final empList = (json['active_field_map'] as List<dynamic>? ?? [])
        .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdminDashboardStats(
      totalEmployees: int.tryParse(summary['total_employees']?.toString() ?? '0') ?? 0,
      activeEmployees: int.tryParse(summary['active_employees']?.toString() ?? '0') ?? 0,
      onFieldEmployees: int.tryParse(summary['on_field_employees']?.toString() ?? '0') ?? 0,
      todayCollection: double.tryParse(summary['today_collection']?.toString() ?? '0') ?? 0.0,
      monthlyCollection: double.tryParse(summary['monthly_collection']?.toString() ?? '0') ?? 0.0,
      totalPending: double.tryParse(summary['total_pending']?.toString() ?? '0') ?? 0.0,
      totalTarget: double.tryParse(summary['total_target']?.toString() ?? '0') ?? 0.0,
      totalCollected: double.tryParse(summary['total_collected']?.toString() ?? '0') ?? 0.0,
      achievementPercent: double.tryParse(summary['achievement_percent']?.toString() ?? '0') ?? 0.0,
      tasksCount: tasksMap,
      paymentMethods: (json['payment_methods'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      rankings: (json['rankings'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      recentTransactions: txList,
      activeFieldMap: empList,
    );
  }
}

class EmployeeDashboardStats {
  final double dailyTarget;
  final double todayCollected;
  final double todayPending;
  final double completionRate;
  final String currentStatus;
  final bool isTrackingEnabled;
  final int? batteryLevel;
  final Map<String, dynamic>? attendance;
  final Map<String, dynamic>? locationSession;
  final Map<String, int> taskCounts;
  final List<Map<String, dynamic>> todayVisits;

  EmployeeDashboardStats({
    required this.dailyTarget,
    required this.todayCollected,
    required this.todayPending,
    required this.completionRate,
    required this.currentStatus,
    required this.isTrackingEnabled,
    this.batteryLevel,
    this.attendance,
    this.locationSession,
    required this.taskCounts,
    required this.todayVisits,
  });

  factory EmployeeDashboardStats.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] as Map<String, dynamic>? ?? {};
    final tasksMap = (json['task_counts'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, int.tryParse(v.toString()) ?? 0),
    );

    return EmployeeDashboardStats(
      dailyTarget: double.tryParse(metrics['daily_target']?.toString() ?? '25000') ?? 25000.0,
      todayCollected: double.tryParse(metrics['today_collected']?.toString() ?? '0') ?? 0.0,
      todayPending: double.tryParse(metrics['today_pending']?.toString() ?? '0') ?? 0.0,
      completionRate: double.tryParse(metrics['completion_rate']?.toString() ?? '0') ?? 0.0,
      currentStatus: metrics['current_status']?.toString() ?? 'offline',
      isTrackingEnabled: metrics['is_tracking_enabled'] == true,
      batteryLevel: int.tryParse(metrics['battery_level']?.toString() ?? ''),
      attendance: json['attendance'] as Map<String, dynamic>?,
      locationSession: json['location_session'] as Map<String, dynamic>?,
      taskCounts: tasksMap,
      todayVisits: (json['today_visits'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }
}
