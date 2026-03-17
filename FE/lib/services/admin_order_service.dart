import 'package:dio/dio.dart';

import '../config/api_config.dart';

String _extractObjectId(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    final id = value['_id'];
    if (id is String) return id;
  }
  return '';
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
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

class AdminOrderService {
  final Dio _dio = ApiConfig.createDioClient();

  /// Get all orders (admin view)
  Future<List<AdminOrderItem>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }

      final response = await _dio.get('/orders/admin/all', queryParameters: params);

      final payload = response.data as Map<String, dynamic>;
        var items = ((payload['data']?['orders'] as List<dynamic>?) ?? [])
          .map(_asMap)
          .toList();

      return items.map(AdminOrderItem.fromJson).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get single order details
  Future<AdminOrderItem> getOrderDetails(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      final payload = response.data as Map<String, dynamic>;
      return AdminOrderItem.fromJson(_asMap(payload['data']?['order']));
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status
  Future<AdminOrderItem> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      final response = await _dio.patch(
        '/orders/$orderId/status',
        data: {'orderStatus': newStatus},
      );

      final payload = response.data as Map<String, dynamic>;
      return AdminOrderItem.fromJson(_asMap(payload['data']?['order']));
    } catch (e) {
      rethrow;
    }
  }

  Future<AdminOrderItem> createOrderByAdmin({
    required String userId,
    required List<AdminCreateOrderItem> items,
    required String rentalType,
    int? durationHours,
  }) async {
    final response = await _dio.post(
      '/orders/admin/create',
      data: {
        'userId': userId,
        'items': items.map((item) => item.toJson()).toList(),
        'rentalType': rentalType,
        if (durationHours != null) 'durationHours': durationHours,
      },
    );

    final payload = response.data as Map<String, dynamic>;
    return AdminOrderItem.fromJson(_asMap(payload['data']?['order']));
  }

  Future<AdminOrderItem> endRental(String orderId) async {
    final response = await _dio.post('/orders/$orderId/end-rental');
    final payload = response.data as Map<String, dynamic>;
    return AdminOrderItem.fromJson(_asMap(payload['data']?['order']));
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final response = await _dio.get('/orders/admin/all', queryParameters: {'limit': 1});
      final payload = response.data as Map<String, dynamic>;
      final orders = (payload['data']?['orders'] as List<dynamic>? ?? [])
          .map(_asMap)
          .toList();

      int totalOrders = payload['data']?['pagination']?['total'] as int? ?? 0;
        int pendingOrders = orders
          .where((o) => o['orderStatus'] == 'PENDING')
          .length;
        int completedOrders = orders
          .where((o) => o['orderStatus'] == 'SUCCESS')
          .length;
      double totalRevenue = orders.fold(
        0.0,
        (sum, o) => sum + _asDouble(o['totalPrice']),
      );

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'totalRevenue': totalRevenue,
      };
    } catch (e) {
      return {
        'totalOrders': 0,
        'pendingOrders': 0,
        'completedOrders': 0,
        'totalRevenue': 0.0,
      };
    }
  }
}

class AdminOrderItem {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final List<OrderItemDetail> items;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String rentalType;
  final double totalPrice;
  final double totalAmount;
  final double depositAmount;
  final DateTime? rentalStartTime;
  final DateTime? rentalEndTime;
  final DateTime? actualEndTime;
  final bool isEditable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminOrderItem({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    this.items = const [],
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    this.rentalType = 'HOURLY',
    required this.totalPrice,
    required this.totalAmount,
    this.depositAmount = 0,
    this.rentalStartTime,
    this.rentalEndTime,
    this.actualEndTime,
    this.isEditable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final userRaw = json['userId'];
    final userMap = _asMap(userRaw);
    final normalizedStatus = _normalizeOrderStatus(json['orderStatus']);
    return AdminOrderItem(
      id: _extractObjectId(json['_id']),
      userId: _extractObjectId(userRaw),
      userName: userMap['name'] as String?,
      userEmail: userMap['email'] as String?,
      items: rawItems
          .map((item) => OrderItemDetail.fromJson(_asMap(item)))
          .toList(),
        orderStatus: normalizedStatus,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
        rentalType: json['rentalType'] as String? ?? 'HOURLY',
      totalPrice: _asDouble(json['totalPrice']),
      totalAmount: _asDouble(json['totalAmount']) > 0
          ? _asDouble(json['totalAmount'])
          : _asDouble(json['totalPrice']),
      depositAmount: _asDouble(json['depositAmount']),
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
          : !['CANCELLED', 'SUCCESS'].contains(normalizedStatus),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class OrderItemDetail {
  final String toyId;
  final String? toyName;
  final int quantity;
  final double rentalPrice;
  final int rentalDurationHours;

  OrderItemDetail({
    required this.toyId,
    this.toyName,
    required this.quantity,
    required this.rentalPrice,
    required this.rentalDurationHours,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    final toyRaw = json['toyId'];
    final toyMap = _asMap(toyRaw);
    return OrderItemDetail(
      toyId: _extractObjectId(toyRaw),
      toyName: toyMap['name'] as String?,
      quantity: _asInt(json['quantity'], 1),
      rentalPrice: _asDouble(json['rentalPrice']),
      rentalDurationHours: _asInt(json['rentalDurationHours'], 24),
    );
  }
}

class AdminCreateOrderItem {
  final String toyId;
  final int quantity;

  AdminCreateOrderItem({
    required this.toyId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'toyId': toyId,
      'quantity': quantity,
    };
  }
}
