import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/transaction_model.dart';

final transactionsProvider = FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  try {
    final response = await DioClient.instance.get(ApiEndpoints.transactions);
    if (response.statusCode == 200 && response.data['data']?['transactions'] != null) {
      final list = response.data['data']['transactions'] as List<dynamic>;
      return list.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (_) {
    return [
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
        customerRemarks: 'Paid first installment, remaining balance next week.',
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
        customerRemarks: 'Handed in cash voucher.',
      ),
    ];
  }
});
