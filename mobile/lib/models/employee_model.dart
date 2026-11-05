class EmployeeModel {
  final int id;
  final int userId;
  final String employeeCode;
  final String designation;
  final String department;
  final String joiningDate;
  final double dailyTarget;
  final double monthlyTarget;
  final String? emergencyContact;
  final String workStartTime;
  final String workEndTime;
  final bool isTrackingEnabled;
  final String currentStatus; // 'offline', 'online', 'in_field', 'on_break'
  final int? batteryLevel;

  // Joined user details
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final double totalCollectedMonth;
  final int activeTasksCount;
  final double? lastLat;
  final double? lastLng;
  final String? lastLocationTime;

  EmployeeModel({
    required this.id,
    required this.userId,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.joiningDate,
    required this.dailyTarget,
    required this.monthlyTarget,
    this.emergencyContact,
    required this.workStartTime,
    required this.workEndTime,
    required this.isTrackingEnabled,
    required this.currentStatus,
    this.batteryLevel,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.totalCollectedMonth = 0.0,
    this.activeTasksCount = 0,
    this.lastLat,
    this.lastLng,
    this.lastLocationTime,
  });

  bool get isOnline => currentStatus == 'online' || currentStatus == 'in_field';
  bool get isInField => currentStatus == 'in_field';

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      employeeCode: json['employee_code']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Field Collection Executive',
      department: json['department']?.toString() ?? 'Operations',
      joiningDate: json['joining_date']?.toString() ?? '',
      dailyTarget: double.tryParse(json['daily_target']?.toString() ?? '25000') ?? 25000,
      monthlyTarget: double.tryParse(json['monthly_target']?.toString() ?? '600000') ?? 600000,
      emergencyContact: json['emergency_contact']?.toString(),
      workStartTime: json['work_start_time']?.toString() ?? '09:00:00',
      workEndTime: json['work_end_time']?.toString() ?? '19:00:00',
      isTrackingEnabled: json['is_tracking_enabled'] == 1 || json['is_tracking_enabled'] == true,
      currentStatus: json['current_status']?.toString() ?? 'offline',
      batteryLevel: int.tryParse(json['battery_level']?.toString() ?? ''),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      totalCollectedMonth: double.tryParse(json['total_collected_month']?.toString() ?? '0') ?? 0.0,
      activeTasksCount: int.tryParse(json['active_tasks_count']?.toString() ?? '0') ?? 0,
      lastLat: double.tryParse(json['last_lat']?.toString() ?? json['latitude']?.toString() ?? ''),
      lastLng: double.tryParse(json['last_lng']?.toString() ?? json['longitude']?.toString() ?? ''),
      lastLocationTime: json['last_location_time']?.toString() ?? json['recorded_at']?.toString(),
    );
  }
}
