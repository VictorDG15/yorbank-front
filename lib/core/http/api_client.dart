import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/secure_token_storage.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8081',
);

final tokenStorageProvider = Provider(
  (ref) => SecureTokenStorage(const FlutterSecureStorage()),
);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(AuthInterceptor(storage));
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (object) => debugPrint(object.toString()),
      ),
    );
  }
  return dio;
});

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final SecureTokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublicAuthPath(options.path)) {
      final token = await _storage.accessToken();
      if (token != null && token.isNotEmpty) {
        if (_looksLikeJwt(token)) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          await _storage.clear();
        }
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      await _storage.clear();
    }
    handler.next(err);
  }

  bool _isPublicAuthPath(String path) {
    return path == '/api/v1/auth/register' ||
        path == '/api/v1/auth/login/prepare' ||
        path == '/api/v1/auth/login' ||
        path == '/api/v1/auth/otp/verify';
  }

  bool _looksLikeJwt(String token) {
    return token.split('.').length == 3;
  }
}
