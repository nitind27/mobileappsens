class UserModel {
  final int id;
  final int roleId;
  final String roleName;
  final String email;
  final String username;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final int? employeeId;
  final String? employeeCode;
  final String? designation;
  final String? department;
  final double? dailyTarget;
  final String? currentStatus;
  final bool isTrackingEnabled;

  UserModel({
    required this.id,
    required this.roleId,
    required this.roleName,
    required this.email,
    required this.username,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.employeeId,
    this.employeeCode,
    this.designation,
    this.department,
    this.dailyTarget,
    this.currentStatus,
    this.isTrackingEnabled = false,
  });

  bool get isAdmin => roleName == 'admin';
  bool get isEmployee => roleName == 'employee';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      roleId: int.tryParse(json['role_id']?.toString() ?? '2') ?? 2,
      roleName: json['role_name']?.toString() ?? (json['role_id'] == 1 ? 'admin' : 'employee'),
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      employeeId: int.tryParse(json['employee_id']?.toString() ?? ''),
      employeeCode: json['employee_code']?.toString(),
      designation: json['designation']?.toString(),
      department: json['department']?.toString(),
      dailyTarget: double.tryParse(json['daily_target']?.toString() ?? ''),
      currentStatus: json['current_status']?.toString(),
      isTrackingEnabled: json['is_tracking_enabled'] == 1 || json['is_tracking_enabled'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'role_name': roleName,
      'email': email,
      'username': username,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'employee_id': employeeId,
      'employee_code': employeeCode,
      'designation': designation,
      'department': department,
      'daily_target': dailyTarget,
      'current_status': currentStatus,
      'is_tracking_enabled': isTrackingEnabled,
    };
  }
}
