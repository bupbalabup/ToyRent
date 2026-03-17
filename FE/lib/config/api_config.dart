import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _baseUrlAndroid = String.fromEnvironment(
    'API_BASE_URL_ANDROID',
    defaultValue: 'http://10.0.2.2:5000/api',
  );
  static const String _baseUrlIOS = String.fromEnvironment(
    'API_BASE_URL_IOS',
    defaultValue: 'http://127.0.0.1:5000/api',
  );
  static const String _baseUrlDefault = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000/api',
  );

  static String? _authToken;
  static final Dio dio = createDioClient();

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static String get baseUrl {
    if (kIsWeb) {
      return _baseUrlDefault;
    }

    if (Platform.isAndroid) {
      return _baseUrlAndroid;
    }

    if (Platform.isIOS) {
      return _baseUrlIOS;
    }

    return _baseUrlDefault;
  }

  static Dio createDioClient() {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        responseType: ResponseType.json,
      ),
    );

    // Add interceptors for logging and token injection
    dio.interceptors.add(
      LoggingInterceptor(),
    );

    return dio;
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiConfig._authToken != null && ApiConfig._authToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${ApiConfig._authToken}';
    }

    debugPrint('[REQUEST] ${options.method} ${options.path}');
    debugPrint('[HEADERS] ${options.headers}');
    debugPrint('[BODY] ${options.data}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('[RESPONSE] ${response.statusCode} ${response.requestOptions.path}');
    debugPrint('[DATA] ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('[ERROR] ${err.message}');
    debugPrint('[ERROR DATA] ${err.response?.data}');
    super.onError(err, handler);
  }
}
