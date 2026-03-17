import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/constants.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late SharedPreferences _prefs;
  late final Future<void> _initFuture;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  UserInfoModel? _user;
  bool _isLoggedIn = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  UserInfoModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _user?.role == 'admin';
  bool get isUser => _user?.role == 'user';

  AuthProvider() {
    _initFuture = _initializePreferences();
  }

  /// Initialize SharedPreferences and restore saved state
  Future<void> _initializePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _restoreSession();
  }

  /// Restore session from local storage
  Future<void> _restoreSession() async {
    try {
      _token = _prefs.getString(StorageKeys.authToken);
      final userJson = _prefs.getString(StorageKeys.userData);

      if (_token != null && userJson != null) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        _user = UserInfoModel.fromJson(decoded);
        _isLoggedIn = true;
        ApiConfig.setAuthToken(_token);
        notifyListeners();
      }
    } catch (e) {
      print('Error restoring session: $e');
    }
  }

  /// Perform login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    await _initFuture;
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      // Save token and user data
      _token = response.token;
      _user = UserInfoModel.fromUserData(response.user);
      _isLoggedIn = true;
      ApiConfig.setAuthToken(_token);

      // Persist to local storage
      await _prefs.setString(StorageKeys.authToken, response.token);
      await _prefs.setBool(StorageKeys.isLoggedIn, true);
      await _prefs.setString(StorageKeys.userData, jsonEncode(_user!.toJson()));
      await _prefs.setString('user_role', _user!.role);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String password,
  }) async {
    await _initFuture;
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      _token = response.token;
      _user = UserInfoModel.fromUserData(response.user);
      _isLoggedIn = true;
      ApiConfig.setAuthToken(_token);

      await _prefs.setString(StorageKeys.authToken, response.token);
      await _prefs.setBool(StorageKeys.isLoggedIn, true);
      await _prefs.setString(StorageKeys.userData, jsonEncode(_user!.toJson()));
      await _prefs.setString('user_role', _user!.role);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    await _initFuture;
    try {
      await _prefs.clear();
      _token = null;
      _user = null;
      _isLoggedIn = false;
      _errorMessage = null;
      ApiConfig.setAuthToken(null);
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? avatar,
  }) async {
    await _initFuture;
    _setLoading(true);
    _clearError();

    try {
      final updatedUser = await _authService.updateProfile(
        name: name,
        email: email,
        avatar: avatar,
      );

      _user = UserInfoModel.fromUserData(updatedUser);
      await _prefs.setString(StorageKeys.userData, jsonEncode(_user!.toJson()));

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
  }
}

/// Local user info model
class UserInfoModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatar;

  UserInfoModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.avatar,
  });

  factory UserInfoModel.fromUserData(dynamic userData) {
    return UserInfoModel(
      id: userData.id ?? '',
      name: userData.name ?? '',
      email: userData.email ?? '',
      phone: userData.phone,
      role: userData.role ?? 'user',
      avatar: userData.avatar,
    );
  }

  factory UserInfoModel.fromJson(Map<String, dynamic> json) {
    return UserInfoModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar': avatar,
    };
  }
}
