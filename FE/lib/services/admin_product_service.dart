import 'package:dio/dio.dart';

import '../config/api_config.dart';

String _extractObjectId(dynamic value) {
  if (value is String) return value;
  if (value is Map<String, dynamic>) {
    final id = value['_id'];
    if (id is String) return id;
  }
  return '';
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

double _asDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}

class AdminProductService {
  final Dio _dio = ApiConfig.createDioClient();

  /// Get all products (admin view with all statuses)
  Future<List<AdminProductItem>> getAllProducts({
    int page = 1,
    int limit = 20,
    String? categoryId,
  }) async {
    try {
      final response = await _dio.get(
        '/toys',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );

      final payload = response.data as Map<String, dynamic>;
      final items = ((payload['data']?['items'] as List<dynamic>?) ?? [])
          .map(_asMap)
          .toList();
      return items.map(AdminProductItem.fromJson).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new product
  Future<AdminProductItem> createProduct({
    required String name,
    required String description,
    required double rentalPrice,
    required double depositAmount,
    required int stock,
    required String categoryId,
    required List<String> images,
    int? maxRentalDuration,
  }) async {
    try {
      final response = await _dio.post(
        '/toys',
        data: {
          'name': name,
          'description': description,
          'rentalPrice': rentalPrice,
          'depositAmount': depositAmount,
          'stock': stock,
          'categoryId': categoryId,
          'images': images,
          'maxRentalDuration': maxRentalDuration ?? 24,
        },
      );

      final payload = response.data as Map<String, dynamic>;
      return AdminProductItem.fromJson(_asMap(payload['data']?['toy']));
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing product
  Future<AdminProductItem> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? rentalPrice,
    double? depositAmount,
    int? stock,
    String? categoryId,
    List<String>? images,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (rentalPrice != null) data['rentalPrice'] = rentalPrice;
      if (depositAmount != null) data['depositAmount'] = depositAmount;
      if (stock != null) data['stock'] = stock;
      if (categoryId != null) data['categoryId'] = categoryId;
      if (images != null) data['images'] = images;
      if (isActive != null) data['isActive'] = isActive;

      final response = await _dio.put('/toys/$productId', data: data);

      final payload = response.data as Map<String, dynamic>;
      return AdminProductItem.fromJson(_asMap(payload['data']?['toy']));
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await _dio.delete('/toys/$productId');
    } catch (e) {
      rethrow;
    }
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStats() async {
    try {
      final response = await _dio.get('/toys', queryParameters: {'limit': 1});
      final payload = response.data as Map<String, dynamic>;
      final total = payload['data']?['pagination']?['total'] as int? ?? 0;
      return {
        'totalProducts': total,
        'activeProducts': total,
      };
    } catch (e) {
      return {'totalProducts': 0, 'activeProducts': 0};
    }
  }
}

class AdminProductItem {
  final String id;
  final String name;
  final String description;
  final double rentalPrice;
  final double depositAmount;
  final int stock;
  final bool isActive;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final List<String> images;
  final int maxRentalDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.rentalPrice,
    required this.depositAmount,
    required this.stock,
    required this.isActive,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.images = const [],
    this.maxRentalDuration = 24,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminProductItem.fromJson(Map<String, dynamic> json) {
    final category = json['categoryId'];
    final categoryMap = _asMap(category);
    return AdminProductItem(
      id: _extractObjectId(json['_id']),
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      rentalPrice: _asDouble(json['rentalPrice']),
      depositAmount: _asDouble(json['depositAmount']),
      stock: _asInt(json['stock']),
      isActive: _asBool(json['isActive'], true),
      categoryId: _extractObjectId(category).isEmpty ? null : _extractObjectId(category),
      categoryName: categoryMap['name'] as String?,
        imageUrl: json['imageUrl'] as String? ??
          (((json['images'] as List<dynamic>?) ?? []).isNotEmpty
            ? ((json['images'] as List<dynamic>).first).toString()
            : null),
      images: ((json['images'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList(),
      maxRentalDuration: _asInt(json['maxRentalDuration'], 24),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
