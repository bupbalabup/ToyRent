import 'package:flutter/material.dart';

import '../services/admin_category_service.dart';

class AdminCategoryProvider with ChangeNotifier {
  final AdminCategoryService _service = AdminCategoryService();

  List<AdminCategoryItem> _categories = [];
  bool _loading = false;
  String? _error;

  List<AdminCategoryItem> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch all categories
  Future<void> fetchCategories() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _service.getAllCategories();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create new category
  Future<AdminCategoryItem> createCategory({
    required String name,
    String? icon,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final newCategory = await _service.createCategory(
        name: name,
        icon: icon,
      );

      _categories.add(newCategory);
      _loading = false;
      _error = null;
      notifyListeners();
      return newCategory;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update category
  Future<AdminCategoryItem> updateCategory({
    required String categoryId,
    String? name,
    String? icon,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedCategory = await _service.updateCategory(
        categoryId: categoryId,
        name: name,
        icon: icon,
      );

      final index = _categories.indexWhere((c) => c.id == categoryId);
      if (index >= 0) {
        _categories[index] = updatedCategory;
      }

      _loading = false;
      _error = null;
      notifyListeners();
      return updatedCategory;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String categoryId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      _loading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }
}
