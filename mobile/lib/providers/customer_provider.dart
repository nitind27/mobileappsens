import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_client.dart';
import '../models/customer_model.dart';

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customersProvider = FutureProvider.autoDispose<List<CustomerModel>>((ref) async {
  final search = ref.watch(customerSearchQueryProvider);

  try {
    final response = await DioClient.instance.get(
      ApiEndpoints.customers,
      queryParameters: search.isNotEmpty ? {'search': search} : null,
    );

    if (response.statusCode == 200 && response.data['data']?['customers'] != null) {
      final list = response.data['data']['customers'] as List<dynamic>;
      return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (_) {
    return [
      CustomerModel(
        id: 1,
        customerCode: 'CUST-001',
        businessName: 'Rahul Traders',
        contactPerson: 'Rahul Parekh',
        phone: '+91 98251 33445',
        email: 'rahul@rahultraders.in',
        address: 'Shop 14, Millennium Textile Market, Ring Road',
        city: 'Surat',
        state: 'Gujarat',
        latitude: 21.189025,
        longitude: 72.836520,
        outstandingAmount: 25000.0,
        creditLimit: 150000.0,
        activeTasksCount: 1,
        totalPendingTasksAmount: 15000.0,
      ),
      CustomerModel(
        id: 2,
        customerCode: 'CUST-002',
        businessName: 'Shree Ambica Textiles',
        contactPerson: 'Manoj Agarwal',
        phone: '+91 98240 77889',
        address: 'Plot 42, GIDC Industrial Estate, Pandesara',
        city: 'Surat',
        state: 'Gujarat',
        latitude: 21.135400,
        longitude: 72.825100,
        outstandingAmount: 48500.0,
        creditLimit: 200000.0,
        activeTasksCount: 1,
        totalPendingTasksAmount: 48500.0,
      ),
      CustomerModel(
        id: 3,
        customerCode: 'CUST-003',
        businessName: 'Krishna Electronics & Appliances',
        contactPerson: 'Suresh Patel',
        phone: '+91 94268 99112',
        address: 'Station Road, Opposite Railway Station',
        city: 'Surat',
        state: 'Gujarat',
        latitude: 21.205200,
        longitude: 72.840300,
        outstandingAmount: 18000.0,
        creditLimit: 100000.0,
        activeTasksCount: 0,
        totalPendingTasksAmount: 0.0,
      ),
    ];
  }
});
