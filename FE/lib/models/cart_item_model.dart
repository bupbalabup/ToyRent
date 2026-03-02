import 'toy_model.dart';

class CartItemModel {
  const CartItemModel({required this.toy, required this.quantity});

  final ToyModel toy;
  final int quantity;

  double get subtotal => toy.price * quantity;

  CartItemModel copyWith({ToyModel? toy, int? quantity}) {
    return CartItemModel(
      toy: toy ?? this.toy,
      quantity: quantity ?? this.quantity,
    );
  }
}
