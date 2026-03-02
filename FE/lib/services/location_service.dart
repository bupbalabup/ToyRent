import 'api_service.dart';

class LocationOption {
  const LocationOption({required this.code, required this.name});

  final int code;
  final String name;
}

class LocationService {
  LocationService(this._apiService);

  final ApiService _apiService;

  Future<List<LocationOption>> fetchProvinces() async {
    final response = await _apiService.get('/locations/provinces');
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    final list = (data?['provinces'] as List<dynamic>? ?? const <dynamic>[]);

    return list
        .map(
          (item) => LocationOption(
            code: (item['code'] as num).toInt(),
            name: item['name'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<List<LocationOption>> fetchDistricts(int provinceCode) async {
    final response = await _apiService.get('/locations/provinces/$provinceCode/districts');
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    final list = (data?['districts'] as List<dynamic>? ?? const <dynamic>[]);

    return list
        .map(
          (item) => LocationOption(
            code: (item['code'] as num).toInt(),
            name: item['name'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<List<LocationOption>> fetchWards(int districtCode) async {
    final response = await _apiService.get('/locations/districts/$districtCode/wards');
    final data = (response as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
    final list = (data?['wards'] as List<dynamic>? ?? const <dynamic>[]);

    return list
        .map(
          (item) => LocationOption(
            code: (item['code'] as num).toInt(),
            name: item['name'] as String,
          ),
        )
        .toList(growable: false);
  }
}
