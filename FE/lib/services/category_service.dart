import 'package:dio/dio.dart';
import '../config/api_config.dart';

class CategoryService {
  late final Dio _dio;

  CategoryService() {
    _dio = ApiConfig.createDioClient();
  }

  /// Fetch all categories
  Future<List<CategoryItem>> getCategories() async {
    try {
      final response = await _dio.get('/categories');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final categories = data['data']['categories'] as List?;
          return categories
                  ?.map((item) => CategoryItem.fromJson(item))
                  .toList() ??
              [];
        }
      }

      throw CategoryException('Failed to fetch categories');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw CategoryException(e.toString());
    }
  }

  /// Fetch single category
  Future<CategoryItem> getCategoryById(String categoryId) async {
    try {
      final response = await _dio.get('/categories/$categoryId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return CategoryItem.fromJson(data['data']['category']);
        }
      }

      throw CategoryException('Category not found');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw CategoryException(e.toString());
    }
  }

  CategoryException _handleDioError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['message'] ?? 'Network error';
      return CategoryException(message);
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return CategoryException('Connection timeout');
    }

    return CategoryException('Network error');
  }
}

/// Custom exception
class CategoryException implements Exception {
  final String message;
  CategoryException(this.message);

  @override
  String toString() => message;
}

/// Category item model
class CategoryItem {
  final String id;
  final String name;
  final String? icon;

  CategoryItem({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      icon: json['icon'],
    );
  }
}
