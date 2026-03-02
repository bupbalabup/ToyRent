class ToyModel {
  const ToyModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.rating,
    required this.stock,
    required this.isFeatured,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final double rating;
  final int stock;
  final bool isFeatured;

  factory ToyModel.fromJson(Map<String, dynamic> json) {
    final categoryValue = json['categoryId'];
    final categoryName = categoryValue is Map<String, dynamic>
        ? (categoryValue['name'] as String? ?? 'General')
        : 'General';

    final images = (json['images'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item.toString())
        .toList(growable: false);

    return ToyModel(
      id: (json['_id'] ?? json['id']).toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: images.isNotEmpty ? images.first : '',
      price: (json['rentalPricePerDay'] as num? ?? json['price'] as num? ?? 0).toDouble(),
      category: categoryName,
      rating: (json['ratingAverage'] as num? ?? json['rating'] as num? ?? 0).toDouble(),
      stock: (json['stock'] as num? ?? 0).toInt(),
      isFeatured: (json['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'images': imageUrl.trim().isEmpty ? <String>[] : <String>[imageUrl],
      'rentalPricePerDay': price,
      'stock': stock,
      'isActive': isFeatured,
    };
  }

  ToyModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? category,
    double? rating,
    int? stock,
    bool? isFeatured,
  }) {
    return ToyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      stock: stock ?? this.stock,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
