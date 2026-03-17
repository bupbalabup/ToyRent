import 'package:dio/dio.dart';

import '../config/api_config.dart';

class AdminUserService {
  final Dio _dio = ApiConfig.createDioClient();

  /// Get all users statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _dio.get('/auth/admin/user-stats');
      final payload = response.data as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>? ?? {};

      return {
        'totalUsers': data['totalUsers'] ?? 0,
        'adminUsers': data['adminUsers'] ?? 0,
        'regularUsers': data['regularUsers'] ?? 0,
        'activeUsers': data['activeUsers'] ?? 0,
        'inactiveUsers': data['inactiveUsers'] ?? 0,
        'verifiedUsers': data['verifiedUsers'] ?? 0,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'adminUsers': 0,
        'regularUsers': 0,
        'activeUsers': 0,
        'inactiveUsers': 0,
        'verifiedUsers': 0,
      };
    }
  }

  Future<AdminUsersPage> getAllUsers({
    String search = '',
    String role = 'all',
    String status = 'all',
    String verified = 'all',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/auth/admin/users',
        queryParameters: {
          'search': search,
          'role': role,
          'status': status,
          'verified': verified,
          'page': page,
          'limit': limit,
        },
      );
      final payload = response.data as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final users = (payload['data']?['users'] as List<dynamic>? ?? [])
          .map((item) => AdminUserItem.fromJson(item as Map<String, dynamic>))
          .toList();
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      return AdminUsersPage(
        users: users,
        page: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
        total: (pagination['total'] as num?)?.toInt() ?? users.length,
        hasNextPage: pagination['hasNextPage'] == true,
        hasPreviousPage: pagination['hasPreviousPage'] == true,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AdminUserItem> updateUserRole({
    required String userId,
    required String role,
  }) async {
    final response = await _dio.patch('/auth/admin/users/$userId/role', data: {
      'role': role,
    });
    final payload = response.data as Map<String, dynamic>;
    return AdminUserItem.fromJson(
      payload['data']?['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<AdminUserItem> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    final response = await _dio.patch('/auth/admin/users/$userId/status', data: {
      'isActive': isActive,
    });
    final payload = response.data as Map<String, dynamic>;
    return AdminUserItem.fromJson(
      payload['data']?['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  Future<AdminUserItem> updateUserVerification({
    required String userId,
    required bool isVerified,
  }) async {
    final response = await _dio.patch('/auth/admin/users/$userId/verify', data: {
      'isVerified': isVerified,
    });
    final payload = response.data as Map<String, dynamic>;
    return AdminUserItem.fromJson(
      payload['data']?['user'] as Map<String, dynamic>? ?? <String, dynamic>{},
    );
  }

  /// Get current admin user profile
  Future<AdminUserItem> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final payload = response.data as Map<String, dynamic>;
      return AdminUserItem.fromJson(
        payload['data']['user'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }
}

class AdminUserItem {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final bool isVerified;
  final String? avatar;
  final DateTime? createdAt;

  AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.isActive,
    required this.isVerified,
    this.avatar,
    this.createdAt,
  });

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    return AdminUserItem(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'user',
      isActive: json['isActive'] != false,
      isVerified: json['isVerified'] == true,
      avatar: json['avatar'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class AdminUsersPage {
  final List<AdminUserItem> users;
  final int page;
  final int totalPages;
  final int total;
  final bool hasNextPage;
  final bool hasPreviousPage;

  AdminUsersPage({
    required this.users,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
}
