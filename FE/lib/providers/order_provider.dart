import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/toy_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._orderService);

  final OrderService _orderService;

  bool _isLoading = false;
  String? _error;
  List<OrderModel> _orders = <OrderModel>[];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<OrderModel> get orders => _orders;

  int get totalOrders => _orders.length;
  double get totalSpent => _orders.fold<double>(0, (sum, item) => sum + item.totalPrice);

  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.fetchOrders();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> createOrder({
    required List<(ToyModel, int)> items,
    required DateTime rentalStartDate,
    required DateTime rentalEndDate,
    required String fulfillmentType,
    required String paymentMethod,
    ShippingAddressPayload? shippingAddress,
    String? voucherCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        items: items,
        rentalStartDate: rentalStartDate,
        rentalEndDate: rentalEndDate,
        fulfillmentType: fulfillmentType,
        paymentMethod: paymentMethod,
        shippingAddress: shippingAddress,
        voucherCode: voucherCode,
      );
      _orders = <OrderModel>[order, ..._orders];
      return order;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
