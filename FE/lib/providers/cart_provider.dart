import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String productId;
  final String name;
  final double rentalPrice;
  final double depositAmount;
  final String? imageUrl;
  int rentalDurationHours;
  int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.rentalPrice,
    required this.depositAmount,
    this.imageUrl,
    this.rentalDurationHours = 1,
    this.quantity = 1,
  });

  double get itemTotal => (rentalPrice * rentalDurationHours + depositAmount) * quantity;
  double get rentalTotal => rentalPrice * rentalDurationHours * quantity;
  double get depositTotal => depositAmount * quantity;
}

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  double get totalRentalPrice => _cartItems.fold<double>(
    0,
    (sum, item) => sum + item.rentalTotal,
  );

  double get totalDeposit => _cartItems.fold<double>(
    0,
    (sum, item) => sum + item.depositTotal,
  );

  double get totalPrice => _cartItems.fold<double>(
    0,
    (sum, item) => sum + item.itemTotal,
  );

  int get itemCount => _cartItems.fold<int>(
    0,
    (sum, item) => sum + item.quantity,
  );

  void addToCart({
    required String productId,
    required String name,
    required double rentalPrice,
    required double depositAmount,
    String? imageUrl,
    int rentalDurationHours = 1,
    int quantity = 1,
  }) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == productId,
    );

    if (existingIndex >= 0) {
      // Update existing item
      _cartItems[existingIndex].quantity += quantity;
    } else {
      // Add new item
      _cartItems.add(
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          productId: productId,
          name: name,
          rentalPrice: rentalPrice,
          depositAmount: depositAmount,
          imageUrl: imageUrl,
          rentalDurationHours: rentalDurationHours,
          quantity: quantity,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String cartItemId) {
    _cartItems.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  void updateQuantity(String cartItemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(cartItemId);
      return;
    }
    final index = _cartItems.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      _cartItems[index].quantity = newQuantity;
      notifyListeners();
    }
  }

  void updateRentalDuration(String cartItemId, int newDurationHours) {
    final index = _cartItems.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      _cartItems[index].rentalDurationHours = newDurationHours;
      notifyListeners();
    }
  }

  List<CartItem> getSelectedItems(List<String> selectedIds) {
    return _cartItems
        .where((item) => selectedIds.contains(item.id))
        .toList();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  CartItem? getCartItem(String productId) {
    try {
      return _cartItems.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }
}
