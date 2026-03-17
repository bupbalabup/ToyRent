import 'package:flutter/material.dart';

import '../services/socket_service.dart';

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
  final raw = (value?.toString() ?? '').trim();
  if (raw.isEmpty) return 'PENDING';
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
      return upper;
  }
}

class SocketOrderModel {
  final String id;
  final String orderStatus;
  final String paymentStatus;
  final String paymentMethod;
  final String rentalType;
  final double totalAmount;
  final double totalPrice;
  final double depositAmount;
  final String userId;
  final String? userEmail;
  final List<dynamic> items;
  final DateTime? rentalStartTime;
  final DateTime? rentalEndTime;
  final DateTime? actualEndTime;
  final bool isEditable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SocketOrderModel({
    required this.id,
    required this.orderStatus,
    required this.paymentStatus,
    required this.paymentMethod,
    this.rentalType = 'HOURLY',
    required this.totalAmount,
    required this.totalPrice,
    this.depositAmount = 0,
    this.userId = '',
    this.userEmail,
    this.items = const [],
    this.rentalStartTime,
    this.rentalEndTime,
    this.actualEndTime,
    this.isEditable = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SocketOrderModel.fromJson(Map<String, dynamic> json) {
    final userRaw = json['userId'];
    final userMap = _asMap(userRaw);
    final status = _normalizeOrderStatus(json['orderStatus']);
    return SocketOrderModel(
      id: _extractObjectId(json['_id']),
      orderStatus: status,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      rentalType: json['rentalType'] as String? ?? 'HOURLY',
      totalAmount: _asDouble(json['totalAmount']),
      totalPrice: _asDouble(json['totalPrice']),
      depositAmount: _asDouble(json['depositAmount']),
      userId: _extractObjectId(userRaw),
      userEmail: userMap['email'] as String?,
      items: json['items'] as List<dynamic>? ?? [],
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
          : !['SUCCESS', 'CANCELLED'].contains(status),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class SocketOrderProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();

  List<SocketOrderModel> _orders = [];
  Map<String, SocketOrderModel> _ordersById = {};
  String? _lastUpdatedOrderId;
  DateTime? _lastUpdateTime;

  List<SocketOrderModel> get orders => _orders;
  String? get lastUpdatedOrderId => _lastUpdatedOrderId;
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Initialize socket listeners for order events
  void initializeOrderListeners() {
    // Listen for order creation
    _socketService.on('order_created', (data) {
      _handleOrderCreated(data);
    });

    // Listen for order updates
    _socketService.on('order_updated', (data) {
      _handleOrderUpdated(data);
    });

    // Listen for payment success
    _socketService.on('payment_success', (data) {
      _handlePaymentSuccess(data);
    });

    // Listen for payment failures
    _socketService.on('payment_failed', (data) {
      _handlePaymentFailed(data);
    });

    // Listen for order status changes
    _socketService.on('order_status_changed', (data) {
      _handleOrderStatusChanged(data);
    });

    print('[SocketOrderProvider] Order listeners initialized');
  }

  /// Add orders from API response
  void setOrders(List<SocketOrderModel> orders) {
    _orders = orders;
    _ordersById = {for (var order in orders) order.id: order};
    notifyListeners();
  }

  /// Handle order_created event
  void _handleOrderCreated(Map<String, dynamic> data) {
    try {
      final eventData = data['data'] as Map<String, dynamic>?;
      if (eventData == null) return;

      final order = SocketOrderModel.fromJson(eventData);

      // Add to the beginning of the list
      if (!_ordersById.containsKey(order.id)) {
        _orders.insert(0, order);
      } else {
        _orders[_orders.indexWhere((o) => o.id == order.id)] = order;
      }

      _ordersById[order.id] = order;
      _lastUpdatedOrderId = order.id;
      _lastUpdateTime = DateTime.now();

      print('[SocketOrderProvider] Order created: ${order.id}');
      notifyListeners();
    } catch (e) {
      print('[SocketOrderProvider] Error handling order_created: $e');
    }
  }

  /// Handle order_updated event
  void _handleOrderUpdated(Map<String, dynamic> data) {
    try {
      final eventData = data['data'] as Map<String, dynamic>?;
      if (eventData == null) return;

      final order = SocketOrderModel.fromJson(eventData);

      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        _orders[index] = order;
      }

      _ordersById[order.id] = order;
      _lastUpdatedOrderId = order.id;
      _lastUpdateTime = DateTime.now();

      print('[SocketOrderProvider] Order updated: ${order.id}');
      notifyListeners();
    } catch (e) {
      print('[SocketOrderProvider] Error handling order_updated: $e');
    }
  }

  /// Handle payment_success event
  void _handlePaymentSuccess(Map<String, dynamic> data) {
    try {
      final eventData = data['data'] as Map<String, dynamic>?;
      if (eventData == null) return;

      final order = SocketOrderModel.fromJson(eventData);

      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        _orders[index] = order;
      }

      _ordersById[order.id] = order;
      _lastUpdatedOrderId = order.id;
      _lastUpdateTime = DateTime.now();

      print('[SocketOrderProvider] Payment success for order: ${order.id}');
      notifyListeners();
    } catch (e) {
      print('[SocketOrderProvider] Error handling payment_success: $e');
    }
  }

  /// Handle payment_failed event
  void _handlePaymentFailed(Map<String, dynamic> data) {
    try {
      final eventData = data['data'] as Map<String, dynamic>?;
      final reason = data['reason'] as String?;
      if (eventData == null) return;

      final order = SocketOrderModel.fromJson(eventData);

      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        _orders[index] = order;
      }

      _ordersById[order.id] = order;
      _lastUpdatedOrderId = order.id;
      _lastUpdateTime = DateTime.now();

      print('[SocketOrderProvider] Payment failed for order: ${order.id} - Reason: $reason');
      notifyListeners();
    } catch (e) {
      print('[SocketOrderProvider] Error handling payment_failed: $e');
    }
  }

  /// Handle order_status_changed event
  void _handleOrderStatusChanged(Map<String, dynamic> data) {
    try {
      final eventData = data['data'] as Map<String, dynamic>?;
      final oldStatus = data['oldStatus'] as String?;
      final newStatus = data['newStatus'] as String?;
      if (eventData == null) return;

      final order = SocketOrderModel.fromJson(eventData);

      final index = _orders.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        _orders[index] = order;
      }

      _ordersById[order.id] = order;
      _lastUpdatedOrderId = order.id;
      _lastUpdateTime = DateTime.now();

      print('[SocketOrderProvider] Order status changed: ${order.id} ($oldStatus -> $newStatus)');
      notifyListeners();
    } catch (e) {
      print('[SocketOrderProvider] Error handling order_status_changed: $e');
    }
  }

  /// Get order by ID
  SocketOrderModel? getOrderById(String orderId) {
    return _ordersById[orderId];
  }

  /// Clear listeners
  @override
  void dispose() {
    _socketService.offAll('order_created');
    _socketService.offAll('order_updated');
    _socketService.offAll('payment_success');
    _socketService.offAll('payment_failed');
    _socketService.offAll('order_status_changed');
    super.dispose();
  }
}
