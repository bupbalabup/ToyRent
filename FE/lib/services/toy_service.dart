import '../models/toy_model.dart';
import 'api_service.dart';

class ToyService {
  ToyService(this._apiService);

  final ApiService _apiService;

  Future<List<ToyModel>> fetchToys() async {
    final response = await _apiService.get('/toys');
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    final list = (data?['items'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    return list.map(ToyModel.fromJson).toList(growable: false);
  }

  Future<ToyModel> fetchToyById(String id) async {
    final response = await _apiService.get('/toys/$id');
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return ToyModel.fromJson(data?['toy'] as Map<String, dynamic>);
  }

  Future<ToyModel> createToy(ToyModel model) async {
    final response = await _apiService.post('/toys', model.toJson(), withAuth: true);
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return ToyModel.fromJson(data?['toy'] as Map<String, dynamic>);
  }

  Future<ToyModel> updateToy(ToyModel model) async {
    final response = await _apiService.put('/toys/${model.id}', model.toJson(), withAuth: true);
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    return ToyModel.fromJson(data?['toy'] as Map<String, dynamic>);
  }

  Future<void> deleteToy(String id) async {
    await _apiService.delete('/toys/$id', withAuth: true);
  }
}
