import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthService {
  static const String _userRoleKey = 'user_role';

  /// Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(_userRoleKey) ?? 'user';
      return role == 'admin';
    } catch (e) {
      return false;
    }
  }

  /// Get current user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRoleKey);
    } catch (e) {
      return null;
    }
  }

  /// Set user role (called after login)
  Future<void> setUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userRoleKey, role);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear user role on logout
  Future<void> clearUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userRoleKey);
    } catch (e) {
      rethrow;
    }
  }
}
