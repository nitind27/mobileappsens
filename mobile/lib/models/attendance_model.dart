class AttendanceModel {
  final int id;
  final int employeeId;
  final String date;
  final String checkInTime;
  final double checkInLat;
  final double checkInLng;
  final String? checkInAddress;
  final String? checkOutTime;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkOutAddress;
  final int workDurationMinutes;
  final String status; // 'present', 'late', 'half_day', 'absent'
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.checkInTime,
    required this.checkInLat,
    required this.checkInLng,
    this.checkInAddress,
    this.checkOutTime,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutAddress,
    this.workDurationMinutes = 0,
    required this.status,
    this.notes,
  });

  bool get isCheckedOut => checkOutTime != null && checkOutTime!.isNotEmpty;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      employeeId: int.tryParse(json['employee_id']?.toString() ?? '0') ?? 0,
      date: json['date']?.toString() ?? '',
      checkInTime: json['check_in_time']?.toString() ?? '',
      checkInLat: double.tryParse(json['check_in_lat']?.toString() ?? '0.0') ?? 0.0,
      checkInLng: double.tryParse(json['check_in_lng']?.toString() ?? '0.0') ?? 0.0,
      checkInAddress: json['check_in_address']?.toString(),
      checkOutTime: json['check_out_time']?.toString(),
      checkOutLat: double.tryParse(json['check_out_lat']?.toString() ?? ''),
      checkOutLng: double.tryParse(json['check_out_lng']?.toString() ?? ''),
      checkOutAddress: json['check_out_address']?.toString(),
      workDurationMinutes: int.tryParse(json['work_duration_minutes']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'present',
      notes: json['notes']?.toString(),
    );
  }
}
