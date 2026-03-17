import 'package:flutter/material.dart';

import '../services/admin_product_service.dart';

class AdminProductProvider with ChangeNotifier {
  final AdminProductService _service = AdminProductService();

  List<AdminProductItem> _products = [];
  bool _loading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;

  List<AdminProductItem> get products => _products;
  bool get loading => _loading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  /// Fetch all products
  Future<void> fetchProducts({int page = 1, String? categoryId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _service.getAllProducts(
        page: page,
        limit: 20,
        categoryId: categoryId,
      );
      _currentPage = page;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create new product
  Future<AdminProductItem> createProduct({
    required String name,
    required String description,
    required double rentalPrice,
    required double depositAmount,
    required int stock,
    required String categoryId,
    required List<String> images,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final newProduct = await _service.createProduct(
        name: name,
        description: description,
        rentalPrice: rentalPrice,
        depositAmount: depositAmount,
        stock: stock,
        categoryId: categoryId,
        images: images,
      );

      _products.insert(0, newProduct);
      _loading = false;
      _error = null;
      notifyListeners();
      return newProduct;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update existing product
  Future<AdminProductItem> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? rentalPrice,
    double? depositAmount,
    int? stock,
    String? categoryId,
    List<String>? images,
    bool? isActive,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProduct = await _service.updateProduct(
        productId: productId,
        name: name,
        description: description,
        rentalPrice: rentalPrice,
        depositAmount: depositAmount,
        stock: stock,
        categoryId: categoryId,
        images: images,
        isActive: isActive,
      );

      final index = _products.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        _products[index] = updatedProduct;
      }

      _loading = false;
      _error = null;
      notifyListeners();
      return updatedProduct;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
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

  /// Get product count
  Future<int> getProductCount() async {
    try {
      final stats = await _service.getProductStats();
      return stats['totalProducts'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
