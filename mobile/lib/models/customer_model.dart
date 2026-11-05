class CustomerModel {
  final int id;
  final String customerCode;
  final String businessName;
  final String contactPerson;
  final String phone;
  final String? email;
  final String address;
  final String city;
  final String state;
  final String? postalCode;
  final double latitude;
  final double longitude;
  final double outstandingAmount;
  final double creditLimit;
  final String riskCategory;
  final String? notes;
  final int activeTasksCount;
  final double totalPendingTasksAmount;

  CustomerModel({
    required this.id,
    required this.customerCode,
    required this.businessName,
    required this.contactPerson,
    required this.phone,
    this.email,
    required this.address,
    required this.city,
    required this.state,
    this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.outstandingAmount,
    required this.creditLimit,
    this.riskCategory = 'medium',
    this.notes,
    this.activeTasksCount = 0,
    this.totalPendingTasksAmount = 0.0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      customerCode: json['customer_code']?.toString() ?? '',
      businessName: json['business_name']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? 'Gujarat',
      postalCode: json['postal_code']?.toString(),
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      outstandingAmount: double.tryParse(json['outstanding_amount']?.toString() ?? '0.0') ?? 0.0,
      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? '100000.0') ?? 100000.0,
      riskCategory: json['risk_category']?.toString() ?? 'medium',
      notes: json['notes']?.toString(),
      activeTasksCount: int.tryParse(json['active_tasks_count']?.toString() ?? '0') ?? 0,
      totalPendingTasksAmount: double.tryParse(json['total_pending_tasks_amount']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}
