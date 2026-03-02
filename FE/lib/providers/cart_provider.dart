import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/toy_model.dart';
import '../services/notification_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = <CartItemModel>[];

  List<CartItemModel> get items => List<CartItemModel>.unmodifiable(_items);

  int get totalQuantity => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold<double>(0, (sum, item) => sum + item.subtotal);

  void addToCart(ToyModel toy) {
    final index = _items.indexWhere((item) => item.toy.id == toy.id);

    if (index == -1) {
      _items.add(CartItemModel(toy: toy, quantity: 1));
    } else {
      final current = _items[index];
      _items[index] = current.copyWith(quantity: current.quantity + 1);
    }

    NotificationService.instance.showCartNotification(toy.name);
    notifyListeners();
  }

  void decreaseItem(String toyId) {
    final index = _items.indexWhere((item) => item.toy.id == toyId);
    if (index == -1) return;

    final item = _items[index];
    if (item.quantity == 1) {
      _items.removeAt(index);
    } else {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    }

    notifyListeners();
  }

  void removeItem(String toyId) {
    _items.removeWhere((item) => item.toy.id == toyId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
