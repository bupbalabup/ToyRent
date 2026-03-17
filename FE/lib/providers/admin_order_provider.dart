import 'package:flutter/material.dart';

import '../services/admin_order_service.dart';

class AdminOrderProvider with ChangeNotifier {
  final AdminOrderService _service = AdminOrderService();

  List<AdminOrderItem> _orders = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  String? _selectedStatus;

  List<AdminOrderItem> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  int get currentPage => _currentPage;
  String? get selectedStatus => _selectedStatus;

  final List<String> orderStatuses = [
    'All',
    'PENDING',
    'ACTIVE',
    'SUCCESS',
    'CANCELLED',
    'FAILED'
  ];

  /// Fetch all orders
  Future<void> fetchOrders({int page = 1, String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _service.getAllOrders(
        page: page,
        limit: 20,
        status: status,
      );
      _currentPage = page;
      _selectedStatus = status;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get order details
  Future<AdminOrderItem> getOrderDetails(String orderId) async {
    try {
      return await _service.getOrderDetails(orderId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedOrder = await _service.updateOrderStatus(orderId, newStatus);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = updatedOrder;
      }

      _loading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<AdminOrderItem> createOrderByAdmin({
    required String userId,
    required List<AdminCreateOrderItem> items,
    required String rentalType,
    int? durationHours,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _service.createOrderByAdmin(
        userId: userId,
        items: items,
        rentalType: rentalType,
        durationHours: durationHours,
      );
      _orders.insert(0, order);
      _loading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<AdminOrderItem> endRental(String orderId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.endRental(orderId);
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = updated;
      }
      _loading = false;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Filter orders by status
  List<AdminOrderItem> getOrdersByStatus(String status) {
    if (status == 'All') {
      return _orders;
    }
    return _orders.where((o) => o.orderStatus == status).toList();
  }

  /// Get order statistics
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      return await _service.getOrderStats();
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
