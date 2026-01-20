import 'package:flutter/material.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  // State
  bool _isLoading = false;
  List<CategoryItem> _categories = [];
  String? _errorMessage;
  String? _selectedCategoryId;

  // Getters
  bool get isLoading => _isLoading;
  List<CategoryItem> get categories => _categories;
  String? get errorMessage => _errorMessage;
  String? get selectedCategoryId => _selectedCategoryId;

  /// Fetch all categories
  Future<void> fetchCategories() async {
    try {
      _setLoading(true);
      _clearError();

      _categories = await _categoryService.getCategories();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Select category
  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedCategoryId = null;
    notifyListeners();
  }

  void _setLoading(bool value) => _isLoading = value;
  void _clearError() => _errorMessage = null;
  void _setError(String message) => _errorMessage = message;
}
