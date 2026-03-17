import 'package:dio/dio.dart';
import '../config/api_config.dart';

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

String _asString(dynamic value, [String fallback = '']) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}

String _normalizeOrderStatus(dynamic value) {
  final raw = _asString(value);
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

// Models
class OrderItem {
  final String toyId;
  final double rentalPrice;
  final int rentalDurationHours;
  final int quantity;

  OrderItem({
    required this.toyId,
    required this.rentalPrice,
    required this.rentalDurationHours,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'toyId': toyId,
    'rentalPrice': rentalPrice,
    'rentalDurationHours': rentalDurationHours,
    'quantity': quantity,
  };
}

class OrderData {
  final String id;
  final List<dynamic> items;
  final double totalAmount;
  final double depositAmount;
  final double totalPrice;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String rentalType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? rentalStartTime;
  final DateTime? rentalEndTime;
  final DateTime? actualEndTime;
  final bool isEditable;

  OrderData({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.depositAmount,
    required this.totalPrice,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    this.rentalType = 'HOURLY',
    this.rentalStartTime,
    this.rentalEndTime,
    this.actualEndTime,
    this.isEditable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      id: _asString(json['_id']),
      items: (json['items'] as List<dynamic>? ?? []).map((item) => _asMap(item)).toList(),
      totalAmount: _asDouble(json['totalAmount']),
      depositAmount: _asDouble(json['depositAmount']),
      totalPrice: _asDouble(json['totalPrice']),
        orderStatus: _normalizeOrderStatus(json['orderStatus']),
      paymentStatus: _asString(json['paymentStatus'], 'pending'),
      paymentMethod: _asString(json['paymentMethod'], 'cash'),
        rentalType: _asString(json['rentalType'], 'HOURLY'),
        rentalStartTime: json['rentalStartTime'] != null
          ? DateTime.tryParse(_asString(json['rentalStartTime']))
          : null,
        rentalEndTime: json['rentalEndTime'] != null
          ? DateTime.tryParse(_asString(json['rentalEndTime']))
          : null,
        actualEndTime: json['actualEndTime'] != null
          ? DateTime.tryParse(_asString(json['actualEndTime']))
          : null,
        isEditable: json['isEditable'] is bool
          ? json['isEditable'] as bool
          : !['SUCCESS', 'CANCELLED'].contains(_normalizeOrderStatus(json['orderStatus'])),
      createdAt: DateTime.tryParse(_asString(json['createdAt'])) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(_asString(json['updatedAt'])) ?? DateTime.now(),
    );
  }
}

class CreateOrderRequest {
  final List<OrderItem> items;
  final String paymentMethod;
  final String rentalStartDate;
  final String rentalEndDate;
  final int rentalDurationHours;

  CreateOrderRequest({
    required this.items,
    required this.rentalStartDate,
    required this.rentalEndDate,
    required this.rentalDurationHours,
    this.paymentMethod = 'paypal',
  });

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'paymentMethod': paymentMethod,
    'rentalStartDate': rentalStartDate,
    'rentalEndDate': rentalEndDate,
    'rentalDurationHours': rentalDurationHours,
  };
}

class OrderException implements Exception {
  final String message;
  final String? code;

  OrderException({
    required this.message,
    this.code,
  });

  @override
  String toString() => message;
}

class OrderService {
  final Dio _dio = ApiConfig.dio;

  /// Create a new order
  Future<OrderData> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/orders',
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final orderJson = responseData['data']?['order'] as Map<String, dynamic>? ?? {};
          return OrderData.fromJson(orderJson);
        }
        throw OrderException(
          message: responseData['message'] ?? 'Failed to create order',
        );
      }
      throw OrderException(
        message: 'Failed to create order: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw OrderException(
        message: _getDioErrorMessage(e),
        code: e.response?.statusCode.toString(),
      );
    } catch (e) {
      throw OrderException(message: 'Error creating order: $e');
    }
  }

  /// Get current user's orders
  Future<List<OrderData>> getUserOrders({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/orders/me',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final items = responseData['data']?['orders'] as List<dynamic>? ?? [];
          return items
              .map((item) => OrderData.fromJson(_asMap(item)))
              .toList();
        }
        throw OrderException(
          message: responseData['message'] ?? 'Failed to fetch orders',
        );
      }
      throw OrderException(
        message: 'Failed to fetch orders: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw OrderException(
        message: _getDioErrorMessage(e),
        code: e.response?.statusCode.toString(),
      );
    } catch (e) {
      throw OrderException(message: 'Error fetching orders: $e');
    }
  }

  /// Get order by ID
  Future<OrderData> getOrderById(String orderId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.baseUrl}/orders/$orderId',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          final orderJson = responseData['data']?['order'] as Map<String, dynamic>? ?? {};
          return OrderData.fromJson(orderJson);
        }
        throw OrderException(
          message: responseData['message'] ?? 'Failed to fetch order',
        );
      }
      throw OrderException(
        message: 'Failed to fetch order: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw OrderException(
        message: _getDioErrorMessage(e),
        code: e.response?.statusCode.toString(),
      );
    } catch (e) {
      throw OrderException(message: 'Error fetching order: $e');
    }
  }

  String _getDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 401) {
          return 'Unauthorized. Please login again.';
        } else if (status == 403) {
          return 'You do not have permission to perform this action.';
        } else if (status == 404) {
          return 'Order not found.';
        }
        return 'Error: ${error.response?.data['message'] ?? 'Unknown error'}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'An unknown error occurred.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
