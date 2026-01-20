import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ToyService {
  late final Dio _dio;

  ToyService() {
    _dio = ApiConfig.createDioClient();
  }

  /// Fetch all toys with pagination
  /// Returns: {items: ToyData[], pagination: {...}}
  Future<ToyListResponse> getToys({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? searchQuery,
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        if (categoryId != null) 'categoryId': categoryId,
        if (searchQuery != null && searchQuery.isNotEmpty) 'q': searchQuery,
      };

      final response = await _dio.get(
        '/toys',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ToyListResponse.fromJson(data['data']);
        }
      }

      throw ToyException('Failed to fetch toys');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ToyException(e.toString());
    }
  }

  /// Fetch single toy by ID
  Future<ToyData> getToyById(String toyId) async {
    try {
      final response = await _dio.get('/toys/$toyId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          return ToyData.fromJson(data['data']['toy']);
        }
      }

      throw ToyException('Failed to fetch toy');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ToyException(e.toString());
    }
  }

  /// Search toys
  Future<ToyListResponse> searchToys(String query, {int page = 1, int limit = 10}) async {
    return getToys(page: page, limit: limit, searchQuery: query);
  }

  ToyException _handleDioError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['message'] ?? 'Network error';
      return ToyException(message);
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return ToyException('Connection timeout');
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return ToyException('Request timeout');
    }

    return ToyException('Network error. Check your internet.');
  }
}

/// Custom exception
class ToyException implements Exception {
  final String message;
  ToyException(this.message);

  @override
  String toString() => message;
}

/// Toy list response with pagination
class ToyListResponse {
  final List<ToyData> items;
  final PaginationData pagination;

  ToyListResponse({
    required this.items,
    required this.pagination,
  });

  factory ToyListResponse.fromJson(Map<String, dynamic> json) {
    return ToyListResponse(
      items: (json['items'] as List?)
              ?.map((item) => ToyData.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationData.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Toy data model
class ToyData {
  final String id;
  final String name;
  final String? description;
  final double rentalPrice;
  final double depositAmount;
  final int stock;
  final List<String> images;
  final CategoryData? category;
  final int maxRentalDuration;
  final bool isActive;

  ToyData({
    required this.id,
    required this.name,
    this.description,
    required this.rentalPrice,
    required this.depositAmount,
    required this.stock,
    this.images = const [],
    this.category,
    this.maxRentalDuration = 24,
    this.isActive = true,
  });

  factory ToyData.fromJson(Map<String, dynamic> json) {
    return ToyData(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      description: json['description'],
      rentalPrice: (json['rentalPrice'] ?? 0).toDouble(),
      depositAmount: (json['depositAmount'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      images: List<String>.from(json['images'] ?? []),
      category: json['categoryId'] != null
          ? CategoryData.fromJson(json['categoryId'])
          : null,
      maxRentalDuration: json['maxRentalDuration'] ?? 24,
      isActive: json['isActive'] ?? true,
    );
  }

  bool get hasStock => stock > 0;
}

/// Category data model (nested in toy)
class CategoryData {
  final String id;
  final String name;
  final String? icon;

  CategoryData({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      icon: json['icon'],
    );
  }
}

/// Pagination data
class PaginationData {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationData({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) {
    return PaginationData(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  bool get hasNextPage => page < totalPages;
}
