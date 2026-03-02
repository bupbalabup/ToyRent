class OrderItemModel {
  const OrderItemModel({
    required this.toyId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String toyId;
  final String name;
  final int quantity;
  final double price;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      toyId: (json['toyId'] is Map<String, dynamic>
              ? (json['toyId'] as Map<String, dynamic>)['_id']
              : json['toyId'])
          .toString(),
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num? ?? 1).toInt(),
      price: (json['rentalPricePerDay'] as num? ?? json['price'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'toyId': toyId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.totalPrice,
    required this.items,
  });

  final String id;
  final String userId;
  final String createdAt;
  final double totalPrice;
  final List<OrderItemModel> items;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();

    return OrderModel(
      id: (json['_id'] ?? json['id']).toString(),
      userId: (json['userId'] is Map<String, dynamic>
              ? (json['userId'] as Map<String, dynamic>)['_id']
              : json['userId'])
          .toString(),
      createdAt: (json['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
      totalPrice: (json['totalPrice'] as num? ?? 0).toDouble(),
      items: rawItems.map(OrderItemModel.fromJson).toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'createdAt': createdAt,
      'totalPrice': totalPrice,
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }
}
