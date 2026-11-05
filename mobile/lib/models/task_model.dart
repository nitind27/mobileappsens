class TaskModel {
  final int id;
  final String taskCode;
  final String title;
  final int customerId;
  final int assignedEmployeeId;
  final double targetAmount;
  final double collectedAmount;
  final double pendingAmount;
  final String dueDate;
  final String expectedVisitDate;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String status; // 'pending', 'in_progress', 'completed', 'overdue', 'cancelled'
  final String? additionalInstructions;
  final double completionPercentage;
  final String? completedAt;

  // Joined Customer Info
  final String? customerBusinessName;
  final String? customerContactPerson;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerCity;
  final double? customerLatitude;
  final double? customerLongitude;
  final double? customerOutstanding;

  // Joined Employee Info
  final String? assignedEmployeeName;

  TaskModel({
    required this.id,
    required this.taskCode,
    required this.title,
    required this.customerId,
    required this.assignedEmployeeId,
    required this.targetAmount,
    required this.collectedAmount,
    required this.pendingAmount,
    required this.dueDate,
    required this.expectedVisitDate,
    required this.priority,
    required this.status,
    this.additionalInstructions,
    required this.completionPercentage,
    this.completedAt,
    this.customerBusinessName,
    this.customerContactPerson,
    this.customerPhone,
    this.customerAddress,
    this.customerCity,
    this.customerLatitude,
    this.customerLongitude,
    this.customerOutstanding,
    this.assignedEmployeeName,
  });

  bool get isCompleted => status == 'completed';
  bool get isUrgent => priority == 'urgent';

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      taskCode: json['task_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      customerId: int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      assignedEmployeeId: int.tryParse(json['assigned_employee_id']?.toString() ?? '0') ?? 0,
      targetAmount: double.tryParse(json['target_amount']?.toString() ?? '0.0') ?? 0.0,
      collectedAmount: double.tryParse(json['collected_amount']?.toString() ?? '0.0') ?? 0.0,
      pendingAmount: double.tryParse(json['pending_amount']?.toString() ?? '0.0') ?? 0.0,
      dueDate: json['due_date']?.toString() ?? '',
      expectedVisitDate: json['expected_visit_date']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
      additionalInstructions: json['additional_instructions']?.toString(),
      completionPercentage: double.tryParse(json['completion_percentage']?.toString() ?? '0.0') ?? 0.0,
      completedAt: json['completed_at']?.toString(),
      customerBusinessName: json['business_name']?.toString() ?? json['customer_name']?.toString(),
      customerContactPerson: json['contact_person']?.toString(),
      customerPhone: json['customer_phone']?.toString() ?? json['phone']?.toString(),
      customerAddress: json['customer_address']?.toString() ?? json['address']?.toString(),
      customerCity: json['customer_city']?.toString() ?? json['city']?.toString(),
      customerLatitude: double.tryParse(json['customer_lat']?.toString() ?? json['latitude']?.toString() ?? ''),
      customerLongitude: double.tryParse(json['customer_lng']?.toString() ?? json['longitude']?.toString() ?? ''),
      customerOutstanding: double.tryParse(json['customer_outstanding']?.toString() ?? json['outstanding_amount']?.toString() ?? ''),
      assignedEmployeeName: json['assigned_employee_name']?.toString() ?? json['employee_name']?.toString(),
    );
  }
}
