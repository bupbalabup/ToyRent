import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = ApiConfig.createDioClient();
  }

  Future<UserData> updateProfile({
    required String name,
    required String email,
    String? avatar,
  }) async {
    try {
      final response = await _dio.patch(
        '/auth/profile',
        data: {
          'name': name.trim(),
          'email': email.toLowerCase().trim(),
          'avatar': avatar,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final user = data['data']['user'] as Map<String, dynamic>? ?? {};
          return UserData.fromJson(user);
        }
        throw AuthException(data['message']?.toString() ?? 'Profile update failed');
      }

      throw AuthException('Unexpected response status: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<LoginResponse> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw AuthException('Name, email and password are required');
      }

      final response = await _dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'email': email.toLowerCase().trim(),
          'phone': phone?.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;

        if (data['success'] == true && data['data'] != null) {
          return LoginResponse.fromJson(data['data']);
        }

        throw AuthException(data['message'] ?? 'Register failed');
      }

      throw AuthException('Unexpected response status: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Login user with email and password
  /// Returns: {user: UserData, token: JWT}
  /// Throws: AuthException
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw AuthException('Email and password are required');
      }

      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email.toLowerCase().trim(),
          'password': password,
        },
      );

      // Success response structure from backend
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;

        if (data['success'] == true && data['data'] != null) {
          return LoginResponse.fromJson(data['data']);
        } else {
          throw AuthException(
            data['message'] ?? 'Login failed',
          );
        }
      }

      throw AuthException('Unexpected response status: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  /// Handle Dio exceptions and convert to AuthException
  AuthException _handleDioError(DioException error) {
    if (error.response != null) {
      final Map<String, dynamic> data = error.response?.data ?? {};
      final message = data['message'] ?? 'An error occurred';

      switch (error.response?.statusCode) {
        case 400:
          return AuthException(message);
        case 401:
          return AuthException('Invalid email or password');
        case 409:
          return AuthException('Email already in use');
        case 500:
          return AuthException('Server error. Please try again later.');
        default:
          return AuthException(message);
      }
    }

    if (error.type == DioExceptionType.connectionTimeout) {
      return AuthException('Connection timeout. Check your internet connection.');
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return AuthException('Request timeout. Please try again.');
    }

    if (error.type == DioExceptionType.unknown) {
      return AuthException('Network error. Please check your internet connection.');
    }

    return AuthException('An unexpected error occurred.');
  }
}

/// Custom exception for auth errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}

/// Login response model matching backend structure
class LoginResponse {
  final UserData user;
  final String token;

  LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: UserData.fromJson(json['user'] ?? {}),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'token': token,
      };
}

/// User data model
class UserData {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatar;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.avatar,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatar': avatar,
      };
}
