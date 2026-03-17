import 'package:dio/dio.dart';

import '../config/api_config.dart';

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _extractObjectId(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    final id = value['_id'];
    if (id is String) return id;
  }
  return '';
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String _normalizeOrderStatus(dynamic value) {
  final raw = value?.toString() ?? '';
  final upper = raw.toUpperCase();
  switch (upper) {
    case 'PENDING':
      return 'PENDING';
    case 'ACTIVE':
      return 'ACTIVE';
    case 'SUCCESS':
      return 'SUCCESS';
    case 'CANCELLED':
      return 'CANCELLED';
    case 'FAILED':
      return 'FAILED';
    case 'CONFIRMED':
    case 'DELIVERING':
      return 'ACTIVE';
    case 'COMPLETED':
      return 'SUCCESS';
    default:
      return upper.isEmpty ? 'PENDING' : upper;
  }
}

class RentalService {
  final Dio _dio = ApiConfig.createDioClient();

  String _extractDioMessage(DioException error, {String fallback = 'Request failed'}) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

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
    try {
      final response = await _dio.post('/payments/checkout', data: {
        'orderId': orderId,
        'paymentMethod': paymentMethod,
        if (returnUrl != null) 'returnUrl': returnUrl,
      });

      final payload = response.data as Map<String, dynamic>;
      return PaymentCheckoutResult.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e, fallback: 'Checkout failed'));
    }
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
  final double totalPrice;
  final double depositAmount;
  final String rentalType;
  final DateTime? rentalStartTime;
  final DateTime? rentalEndTime;
  final DateTime? actualEndTime;
  final bool isEditable;
  final String userId;
  final String? userEmail;
  final List<dynamic> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.totalAmount,
    required this.totalPrice,
    this.depositAmount = 0,
    this.rentalType = 'HOURLY',
    this.rentalStartTime,
    this.rentalEndTime,
    this.actualEndTime,
    this.isEditable = true,
    this.userId = '',
    this.userEmail,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final userRaw = json['userId'];
    final userMap = _asMap(userRaw);
    final totalPrice = _asDouble(json['totalPrice']);
    final totalAmount = _asDouble(json['totalAmount']) > 0
        ? _asDouble(json['totalAmount'])
        : totalPrice;

    return OrderModel(
      id: _extractObjectId(json['_id']),
      orderStatus: _normalizeOrderStatus(json['orderStatus']),
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      totalAmount: totalAmount,
      totalPrice: totalPrice,
      depositAmount: _asDouble(json['depositAmount']),
      rentalType: json['rentalType'] as String? ?? 'HOURLY',
      rentalStartTime: json['rentalStartTime'] != null
        ? DateTime.tryParse(json['rentalStartTime'].toString())
        : null,
      rentalEndTime: json['rentalEndTime'] != null
        ? DateTime.tryParse(json['rentalEndTime'].toString())
        : null,
      actualEndTime: json['actualEndTime'] != null
        ? DateTime.tryParse(json['actualEndTime'].toString())
        : null,
      isEditable: json['isEditable'] is bool
        ? json['isEditable'] as bool
        : !['SUCCESS', 'CANCELLED'].contains(_normalizeOrderStatus(json['orderStatus'])),
      userId: _extractObjectId(userRaw),
      userEmail: userMap['email'] as String?,
      items: json['items'] as List<dynamic>? ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
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
      orderStatus: _normalizeOrderStatus(json['orderStatus']),
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
    );
  }
}
