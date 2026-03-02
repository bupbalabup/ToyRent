import '../core/errors/app_exception.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  AuthService(this._apiService);

  final ApiService _apiService;

  Future<(String, UserModel)> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post('/auth/login', <String, dynamic>{
      'email': email,
      'password': password,
    });

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw AppException('Invalid server response');
    }

    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token == null || userJson == null) {
      throw AppException('Invalid login response');
    }

    final user = UserModel.fromJson(userJson);

    return (token, user);
  }

  Future<(String, UserModel)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post('/auth/register', <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    });

    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;

    if (data == null) {
      throw AppException('Invalid server response');
    }

    final token = data['token'] as String?;
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token == null || userJson == null) {
      throw AppException('Invalid register response');
    }

    final user = UserModel.fromJson(userJson);
    return (token, user);
  }
}
