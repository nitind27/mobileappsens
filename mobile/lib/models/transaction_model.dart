class TransactionModel {
  final int id;
  final String transactionCode;
  final int taskId;
  final int customerId;
  final int employeeId;
  final double amountCollected;
  final String paymentMethod; // 'cash', 'upi', 'cheque', 'bank_transfer', 'card'
  final String? transactionReference;
  final String? receiptPhotoUrl;
  final String? signatureUrl;
  final String paymentStatus; // 'pending_verification', 'verified', 'rejected'
  final String? verificationNotes;
  final String? customerRemarks;
  final String collectedAt;

  // Joined metadata
  final String? taskTitle;
  final String? customerName;
  final String? customerPhone;
  final String? employeeName;
  final String? verifiedByName;

  TransactionModel({
    required this.id,
    required this.transactionCode,
    required this.taskId,
    required this.customerId,
    required this.employeeId,
    required this.amountCollected,
    required this.paymentMethod,
    this.transactionReference,
    this.receiptPhotoUrl,
    this.signatureUrl,
    required this.paymentStatus,
    this.verificationNotes,
    this.customerRemarks,
    required this.collectedAt,
    this.taskTitle,
    this.customerName,
    this.customerPhone,
    this.employeeName,
    this.verifiedByName,
  });

  bool get isVerified => paymentStatus == 'verified';
  bool get isPending => paymentStatus == 'pending_verification';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      transactionCode: json['transaction_code']?.toString() ?? '',
      taskId: int.tryParse(json['task_id']?.toString() ?? '0') ?? 0,
      customerId: int.tryParse(json['customer_id']?.toString() ?? '0') ?? 0,
      employeeId: int.tryParse(json['employee_id']?.toString() ?? '0') ?? 0,
      amountCollected: double.tryParse(json['amount_collected']?.toString() ?? '0.0') ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      transactionReference: json['transaction_reference']?.toString(),
      receiptPhotoUrl: json['receipt_photo_url']?.toString(),
      signatureUrl: json['signature_url']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? 'pending_verification',
      verificationNotes: json['verification_notes']?.toString(),
      customerRemarks: json['customer_remarks']?.toString(),
      collectedAt: json['collected_at']?.toString() ?? '',
      taskTitle: json['task_title']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['business_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      employeeName: json['employee_name']?.toString(),
      verifiedByName: json['verified_by_name']?.toString(),
    );
  }
}
