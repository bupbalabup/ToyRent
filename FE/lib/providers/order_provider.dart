import 'package:flutter/material.dart';
import '../services/order_service.dart';

enum OrderFilterType { all, pending, active, completed, failed }

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderData> _orders = [];
  OrderFilterType _filterType = OrderFilterType.all;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 1;

  // Getters
  List<OrderData> get orders => _getFilteredOrders();
  OrderFilterType get filterType => _filterType;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _currentPage < _totalPages;

  /// Fetch user orders
  Future<void> fetchOrders({bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _orders.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orders = await _orderService.getUserOrders(
        page: _currentPage,
        limit: _pageSize,
      );

      if (reset) {
        _orders = orders;
      } else {
        _orders.addAll(orders);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load more orders (pagination)
  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final orders = await _orderService.getUserOrders(
        page: _currentPage,
        limit: _pageSize,
      );
      _orders.addAll(orders);
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _currentPage--;
      _isLoadingMore = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Get single order by ID
  Future<OrderData?> getOrderbyId(String orderId) async {
    try {
      return await _orderService.getOrderById(orderId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Filter orders by type
  void setFilterType(OrderFilterType filterType) {
    _filterType = filterType;
    notifyListeners();
  }

  /// Get filtered orders based on current filter
  List<OrderData> _getFilteredOrders() {
    switch (_filterType) {
      case OrderFilterType.all:
        return _orders;
      case OrderFilterType.pending:
        return _orders
          .where((order) => order.orderStatus == 'PENDING')
            .toList();
      case OrderFilterType.active:
        return _orders
          .where((order) => order.orderStatus == 'ACTIVE')
            .toList();
      case OrderFilterType.completed:
        return _orders
          .where((order) => order.orderStatus == 'SUCCESS')
            .toList();
      case OrderFilterType.failed:
        return _orders
            .where((order) =>
            order.orderStatus == 'CANCELLED' ||
            order.orderStatus == 'FAILED' ||
                order.paymentStatus == 'failed')
            .toList();
    }
  }

  /// Format order status for display
  String formatOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'ACTIVE':
        return 'Active';
      case 'SUCCESS':
        return 'Success';
      case 'CANCELLED':
        return 'Cancelled';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }

  /// Format payment status for display
  String formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  /// Get status color
  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFFA500);
      case 'ACTIVE':
        return const Color(0xFF2196F3);
      case 'SUCCESS':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
      case 'FAILED':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF999999);
    }
  }
}
