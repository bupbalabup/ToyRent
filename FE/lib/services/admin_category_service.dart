import 'package:dio/dio.dart';

import '../config/api_config.dart';

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

class AdminCategoryService {
  final Dio _dio = ApiConfig.createDioClient();

  /// Get all categories
  Future<List<AdminCategoryItem>> getAllCategories() async {
    try {
      final response = await _dio.get('/categories');

      final payload = response.data as Map<String, dynamic>;
      final data = _asMap(payload['data']);
      final items = (data['categories'] as List<dynamic>? ?? [])
          .map(_asMap)
          .toList();
      return items.map(AdminCategoryItem.fromJson).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new category
  Future<AdminCategoryItem> createCategory({
    required String name,
    String? icon,
  }) async {
    try {
      final response = await _dio.post(
        '/categories',
        data: {
          'name': name,
          if (icon != null) 'icon': icon,
        },
      );

      final payload = response.data as Map<String, dynamic>;
      return AdminCategoryItem.fromJson(_asMap(payload['data']?['category']));
    } catch (e) {
      rethrow;
    }
  }

  /// Update category
  Future<AdminCategoryItem> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (icon != null) data['icon'] = icon;

      final response = await _dio.put('/categories/$categoryId', data: data);

      final payload = response.data as Map<String, dynamic>;
      return AdminCategoryItem.fromJson(_asMap(payload['data']?['category']));
    } catch (e) {
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _dio.delete('/categories/$categoryId');
    } catch (e) {
      rethrow;
    }
  }
}

class AdminCategoryItem {
  final String id;
  final String name;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdminCategoryItem({
    required this.id,
    required this.name,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminCategoryItem.fromJson(Map<String, dynamic> json) {
    return AdminCategoryItem(
      id: _extractObjectId(json['_id']),
      name: json['name'] as String? ?? 'Unknown',
      icon: json['icon'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
