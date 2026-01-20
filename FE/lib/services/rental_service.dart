import 'package:dio/dio.dart';

import '../config/api_config.dart';

class RentalService {
  final Dio _dio = ApiConfig.createDioClient();

  Future<List<ToyItem>> getToys({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/toys', queryParameters: {
      'page': page,
      'limit': limit,
      'isActive': true,
    });

    final payload = response.data as Map<String, dynamic>;
    final items = (payload['data']?['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return items.map(ToyItem.fromJson).toList();
  }

  Future<OrderModel> createOrder({
    required String toyId,
    required int quantity,
    required int rentalDurationHours,
    required DateTime startDate,
    required DateTime endDate,
    required String paymentMethod,
  }) async {
    final response = await _dio.post('/orders', data: {
      'items': [
        {
          'toyId': toyId,
          'quantity': quantity,
        }
      ],
      'rentalStartDate': startDate.toIso8601String(),
      'rentalEndDate': endDate.toIso8601String(),
      'rentalDurationHours': rentalDurationHours,
      'paymentMethod': paymentMethod,
    });

    final payload = response.data as Map<String, dynamic>;
    return OrderModel.fromJson(payload['data']['order'] as Map<String, dynamic>);
  }

  Future<List<OrderModel>> getMyOrders() async {
    final response = await _dio.get('/orders/me');
    final payload = response.data as Map<String, dynamic>;
    final list = (payload['data']?['orders'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(OrderModel.fromJson).toList();
  }

  Future<PaymentCheckoutResult> checkout({
    required String orderId,
    required String paymentMethod,
    String? returnUrl,
  }) async {
    final response = await _dio.post('/payments/checkout', data: {
      'orderId': orderId,
      'paymentMethod': paymentMethod,
      if (returnUrl != null) 'returnUrl': returnUrl,
    });

    final payload = response.data as Map<String, dynamic>;
    return PaymentCheckoutResult.fromJson(payload['data'] as Map<String, dynamic>);
  }

  Future<void> capturePaypalPayment({
    required String orderId,
    required String paypalOrderId,
  }) async {
    await _dio.post('/payments/paypal/orders/$orderId/capture', data: {
      'paypalOrderId': paypalOrderId,
    });
  }

  Future<Map<String, dynamic>> syncPaypalPayment({
    required String orderId,
    required String paypalOrderId,
  }) async {
    final response = await _dio.get(
      '/payments/paypal/orders/$orderId/sync',
      queryParameters: {'paypalOrderId': paypalOrderId},
    );

    final payload = response.data as Map<String, dynamic>;
    return payload['data'] as Map<String, dynamic>? ?? {};
  }
}

class ToyItem {
  final String id;
  final String name;
  final String description;
  final double rentalPrice;
  final double depositAmount;

  ToyItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rentalPrice,
    required this.depositAmount,
  });

  factory ToyItem.fromJson(Map<String, dynamic> json) {
    return ToyItem(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown toy',
      description: json['description'] as String? ?? '',
      rentalPrice: (json['rentalPrice'] as num?)?.toDouble() ?? 0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OrderModel {
  final String id;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final double totalAmount;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.totalAmount,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] as String? ?? '',
      orderStatus: json['orderStatus'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}

class PaymentCheckoutResult {
  final String orderId;
  final String? paypalOrderId;
  final String? paymentUrl;
  final String orderStatus;
  final String paymentStatus;

  PaymentCheckoutResult({
    required this.orderId,
    required this.paypalOrderId,
    required this.paymentUrl,
    required this.orderStatus,
    required this.paymentStatus,
  });

  factory PaymentCheckoutResult.fromJson(Map<String, dynamic> json) {
    return PaymentCheckoutResult(
      orderId: json['orderId'] as String? ?? '',
      paypalOrderId: json['paypalOrderId'] as String?,
      paymentUrl: json['paymentUrl'] as String?,
      orderStatus: json['orderStatus'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
    );
  }
}
