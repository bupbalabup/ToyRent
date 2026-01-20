import 'package:flutter/material.dart';
import '../services/toy_service.dart';

class ProductProvider extends ChangeNotifier {
  final ToyService _toyService = ToyService();

  // State
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<ToyItem> _products = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalPages = 0;
  String? _selectedCategoryId;
  String? _searchQuery;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  List<ToyItem> get products => _products;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  bool get hasMore => _currentPage < _totalPages;

  /// Fetch initial products
  Future<void> fetchProducts({
    String? categoryId,
    String? query,
    bool clearPrevious = true,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      if (clearPrevious) {
        _products.clear();
        _currentPage = 1;
      }

      _selectedCategoryId = categoryId;
      _searchQuery = query;

      final response = await _toyService.getToys(
        page: _currentPage,
        limit: _pageSize,
        categoryId: categoryId,
        searchQuery: query,
      );

      _products = response.items.map((toy) => ToyItem.fromToyData(toy)).toList();
      _totalPages = response.pagination.totalPages;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (!hasMore || _isLoadingMore) return;

    try {
      _setLoadingMore(true);

      _currentPage++;

      final response = await _toyService.getToys(
        page: _currentPage,
        limit: _pageSize,
        categoryId: _selectedCategoryId,
        searchQuery: _searchQuery,
      );

      _products.addAll(
        response.items.map((toy) => ToyItem.fromToyData(toy)),
      );

      _setLoadingMore(false);
      notifyListeners();
    } catch (e) {
      _currentPage--; // Revert page increment on error
      _setLoadingMore(false);
      notifyListeners();
    }
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await fetchProducts(clearPrevious: true);
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      _products.clear();
      _currentPage = 1;
      _searchQuery = query;

      final response = await _toyService.getToys(
        page: 1,
        limit: _pageSize,
        searchQuery: query,
      );

      _products = response.items.map((toy) => ToyItem.fromToyData(toy)).toList();
      _totalPages = response.pagination.totalPages;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Filter by category
  Future<void> filterByCategory(String? categoryId) async {
    await fetchProducts(categoryId: categoryId, clearPrevious: true);
  }

  void _setLoading(bool value) => _isLoading = value;
  void _setLoadingMore(bool value) => _isLoadingMore = value;
  void _clearError() => _errorMessage = null;
  void _setError(String message) => _errorMessage = message;
}

/// Local toy item model (for UI)
class ToyItem {
  final String id;
  final String name;
  final double rentalPrice;
  final double depositAmount;
  final String? imageUrl;
  final bool inStock;
  final String? categoryName;

  ToyItem({
    required this.id,
    required this.name,
    required this.rentalPrice,
    required this.depositAmount,
    this.imageUrl,
    required this.inStock,
    this.categoryName,
  });

  factory ToyItem.fromToyData(dynamic toyData) {
    return ToyItem(
      id: toyData.id,
      name: toyData.name,
      rentalPrice: toyData.rentalPrice,
      depositAmount: toyData.depositAmount,
      imageUrl: toyData.images.isNotEmpty ? toyData.images.first : null,
      inStock: toyData.hasStock,
      categoryName: toyData.category?.name,
    );
  }
}
