import 'package:flutter/foundation.dart';

import '../models/toy_model.dart';
import '../services/toy_service.dart';

class ToyProvider extends ChangeNotifier {
  ToyProvider(this._toyService);

  final ToyService _toyService;

  List<ToyModel> _toys = <ToyModel>[];
  final Set<String> _favoriteIds = <String>{};
  bool _isLoading = false;
  String? _error;
  String _query = '';
  String _selectedCategory = 'All';

  List<ToyModel> get toys => _toys;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  List<String> get categories => <String>{'All', ..._toys.map((e) => e.category)}.toList();

  List<ToyModel> get featured => _toys.where((e) => e.isFeatured).toList();

  List<ToyModel> get visibleToys {
    Iterable<ToyModel> result = _toys;

    if (_selectedCategory != 'All') {
      result = result.where((item) => item.category == _selectedCategory);
    }

    if (_query.trim().isNotEmpty) {
      final query = _query.toLowerCase();
      result = result.where(
        (item) =>
            item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query),
      );
    }

    return result.toList(growable: false);
  }

  List<ToyModel> get favorites => _toys.where((item) => _favoriteIds.contains(item.id)).toList();

  bool isFavorite(String toyId) => _favoriteIds.contains(toyId);

  Future<void> fetchToys() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _toys = await _toyService.fetchToys();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createToy(ToyModel toy) async {
    final created = await _toyService.createToy(toy);
    _toys = <ToyModel>[created, ..._toys];
    notifyListeners();
  }

  Future<void> updateToy(ToyModel toy) async {
    final updated = await _toyService.updateToy(toy);
    _toys = _toys.map((item) => item.id == toy.id ? updated : item).toList(growable: false);
    notifyListeners();
  }

  Future<void> deleteToy(String toyId) async {
    await _toyService.deleteToy(toyId);
    _toys = _toys.where((item) => item.id != toyId).toList(growable: false);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void setCategory(String value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void toggleFavorite(String toyId) {
    if (_favoriteIds.contains(toyId)) {
      _favoriteIds.remove(toyId);
    } else {
      _favoriteIds.add(toyId);
    }
    notifyListeners();
  }
}
