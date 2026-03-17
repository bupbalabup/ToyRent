import 'package:dio/dio.dart';
import '../config/api_config.dart';

class PaymentData {
  final String id;
  final String orderId;
  final String provider;
  final String? transactionId;
  final double amount;
  final String status;
  final DateTime createdAt;

  PaymentData({
    required this.id,
    required this.orderId,
    required this.provider,
    this.transactionId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['_id'] ?? '',
      orderId: json['orderId'] ?? '',
      provider: json['provider'] ?? 'cash',
      transactionId: json['transactionId'],
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class CheckoutResponse {
  final String orderId;
  final String? paypalOrderId;
  final String orderStatus;
  final String paymentStatus;
  final String? paymentUrl;

  CheckoutResponse({
    required this.orderId,
    required this.paypalOrderId,
    required this.orderStatus,
    required this.paymentStatus,
    this.paymentUrl,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      orderId: json['orderId'] ?? '',
      paypalOrderId: json['paypalOrderId'],
      orderStatus: json['orderStatus'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      paymentUrl: json['paymentUrl'],
    );
  }
}

class PaymentException implements Exception {
  final String message;
  final String? code;

  PaymentException({
    required this.message,
    this.code,
  });

  @override
  String toString() => message;
}

class PaymentService {
  final Dio _dio = ApiConfig.dio;

  /// Initiate checkout (PayPal payment)
  Future<CheckoutResponse> checkout({
    required String orderId,
    required String paymentMethod,
    String? returnUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/checkout',
        data: {
          'orderId': orderId,
          'paymentMethod': paymentMethod,
          if (returnUrl != null) 'returnUrl': returnUrl,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return CheckoutResponse.fromJson(responseData['data']);
        }
        throw PaymentException(
          message: responseData['message'] ?? 'Checkout failed',
        );
      }
      throw PaymentException(
        message: 'Checkout failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw PaymentException(
        message: _getDioErrorMessage(e),
        code: e.response?.statusCode.toString(),
      );
    } catch (e) {
      throw PaymentException(message: 'Error during checkout: $e');
    }
  }

  /// Sync PayPal payment status
  Future<CheckoutResponse> syncPaymentStatus(
    String orderId,
    String paypalOrderId,
  ) async {
    try {
      final response = await _dio.get(
        '/payments/paypal/orders/$orderId/sync',
        queryParameters: {'paypalOrderId': paypalOrderId},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return CheckoutResponse.fromJson(responseData['data'] ?? {});
        }
        throw PaymentException(
          message: responseData['message'] ?? 'Failed to sync payment',
        );
      }
      throw PaymentException(
        message: 'Failed to sync payment: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw PaymentException(
        message: _getDioErrorMessage(e),
        code: e.response?.statusCode.toString(),
      );
    } catch (e) {
      throw PaymentException(message: 'Error syncing payment: $e');
    }
  }

  /// Capture PayPal payment
  Future<CheckoutResponse> capturePayment(
    String orderId,
    String paypalOrderId,
  ) async {
    try {
      final response = await _dio.post(
        '/payments/paypal/orders/$orderId/capture',
        data: {'paypalOrderId': paypalOrderId},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;
        if (responseData['success'] == true) {
          return CheckoutResponse.fromJson(responseData['data'] ?? {});
        }
        throw PaymentException(
          message: responseData['message'] ?? 'Payment capture failed',
        );
      }
      throw PaymentException(
        message: 'Payment capture failed: ${response.statusCode}',
      );
    } on DioException catch (e) {
      throw PaymentException(
        message: _getDioErrorMessage(e),
        code: e.response?.statusCode.toString(),
      );
    } catch (e) {
      throw PaymentException(message: 'Error capturing payment: $e');
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
        } else if (status == 404) {
          return 'Order not found.';
        } else if (status == 500) {
          final backendMessage = error.response?.data['message']?.toString();
          if (backendMessage != null && backendMessage.isNotEmpty) {
            return backendMessage;
          }
          return 'Payment service is not configured on server. Please contact admin.';
        }
        return 'Error: ${error.response?.data['message'] ?? 'Unknown error'}';
      case DioExceptionType.cancel:
        return 'Payment was cancelled.';
      case DioExceptionType.unknown:
        return 'An unknown error occurred.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
