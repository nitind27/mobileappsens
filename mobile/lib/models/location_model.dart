class LocationBreadcrumb {
  final int id;
  final int sessionId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final int? batteryLevel;
  final String recordedAt;

  LocationBreadcrumb({
    required this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    this.batteryLevel,
    required this.recordedAt,
  });

  factory LocationBreadcrumb.fromJson(Map<String, dynamic> json) {
    return LocationBreadcrumb(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sessionId: int.tryParse(json['session_id']?.toString() ?? '0') ?? 0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      accuracy: double.tryParse(json['accuracy']?.toString() ?? '0.0') ?? 0.0,
      speed: double.tryParse(json['speed']?.toString() ?? '0.0') ?? 0.0,
      heading: double.tryParse(json['heading']?.toString() ?? '0.0') ?? 0.0,
      batteryLevel: int.tryParse(json['battery_level']?.toString() ?? ''),
      recordedAt: json['recorded_at']?.toString() ?? '',
    );
  }
}

class LocationSessionModel {
  final int id;
  final int employeeId;
  final String startTime;
  final String? endTime;
  final String status; // 'active', 'paused', 'completed', 'stopped'
  final String consentGrantedAt;
  final double totalDistanceKm;

  LocationSessionModel({
    required this.id,
    required this.employeeId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.consentGrantedAt,
    this.totalDistanceKm = 0.0,
  });

  bool get isActive => status == 'active';

  factory LocationSessionModel.fromJson(Map<String, dynamic> json) {
    return LocationSessionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      employeeId: int.tryParse(json['employee_id']?.toString() ?? '0') ?? 0,
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString(),
      status: json['status']?.toString() ?? 'stopped',
      consentGrantedAt: json['consent_granted_at']?.toString() ?? '',
      totalDistanceKm: double.tryParse(json['total_distance_km']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}
