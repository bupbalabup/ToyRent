import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';

class ApiService {
  ApiService(this._tokenProvider);

  final Future<String?> Function() _tokenProvider;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${AppConstants.baseUrl}$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (withAuth) {
      final token = await _tokenProvider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _parse(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Never _throwFromResponse(http.Response response) {
    String message = 'Request failed';
    try {
      final parsed = _parse(response);
      if (parsed is Map<String, dynamic> && parsed['message'] is String) {
        message = parsed['message'] as String;
      }
    } catch (_) {}

    throw AppException(message, statusCode: response.statusCode);
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool withAuth = false,
  }) async {
    try {
      final response = await http
          .get(_uri(path, query), headers: await _headers(withAuth: withAuth))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parse(response);
      }
      _throwFromResponse(response);
    } on AppException {
      rethrow;
    } on SocketException {
      throw AppException('Network error. Please check your connection.');
    } on http.ClientException {
      throw AppException('Network error. Please check your connection.');
    } on FormatException {
      throw AppException('Invalid response format from server.');
    } on TimeoutException {
      throw AppException('Request timeout. Please try again.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body, {bool withAuth = false}) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parse(response);
      }
      _throwFromResponse(response);
    } on AppException {
      rethrow;
    } on SocketException {
      throw AppException('Network error. Please check your connection.');
    } on http.ClientException {
      throw AppException('Network error. Please check your connection.');
    } on FormatException {
      throw AppException('Invalid response format from server.');
    } on TimeoutException {
      throw AppException('Request timeout. Please try again.');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body, {bool withAuth = false}) async {
    try {
      final response = await http
          .put(
            _uri(path),
            headers: await _headers(withAuth: withAuth),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parse(response);
      }
      _throwFromResponse(response);
    } on AppException {
      rethrow;
    } on SocketException {
      throw AppException('Network error. Please check your connection.');
    } on http.ClientException {
      throw AppException('Network error. Please check your connection.');
    } on FormatException {
      throw AppException('Invalid response format from server.');
    } on TimeoutException {
      throw AppException('Request timeout. Please try again.');
    }
  }

  Future<void> delete(String path, {bool withAuth = false}) async {
    try {
      final response = await http
          .delete(_uri(path), headers: await _headers(withAuth: withAuth))
          .timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      _throwFromResponse(response);
    } on AppException {
      rethrow;
    } on SocketException {
      throw AppException('Network error. Please check your connection.');
    } on http.ClientException {
      throw AppException('Network error. Please check your connection.');
    } on TimeoutException {
      throw AppException('Request timeout. Please try again.');
    }
  }
}
