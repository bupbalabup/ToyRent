import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._localStorageService);

  final AuthService _authService;
  final LocalStorageService _localStorageService;

  bool _isLoading = false;
  String? _error;
  String? _token;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  UserModel? get user => _user;
  String? get token => _token;

  Future<void> bootstrap() async {
    _isLoading = true;

    try {
      final loggedIn = await _localStorageService.isLoggedIn();
      if (!loggedIn) return;

      _token = await _localStorageService.getToken();
      _user = await _localStorageService.getUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);

    try {
      final result = await _authService.login(email: email, password: password);
      _token = result.$1;
      _user = result.$2;
      await _localStorageService.saveSession(token: _token!, user: _user!);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    try {
      final result = await _authService.register(name: name, email: email, password: password);
      _token = result.$1;
      _user = result.$2;
      await _localStorageService.saveSession(token: _token!, user: _user!);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _localStorageService.clearSession();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
