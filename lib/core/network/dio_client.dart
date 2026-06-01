import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
    receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(ref));
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('DIO: $obj'),
    ));
  }

  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

class AuthInterceptor extends Interceptor {
  final Ref ref;
  static String? _cachedToken;
  static bool _isTokenLoaded = false;

  AuthInterceptor(this.ref);

  // Allow clearing cache from outside (e.g. on logout)
  static void clearTokenCache() {
    _cachedToken = null;
    _isTokenLoaded = false;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_isTokenLoaded) {
      final storage = ref.read(secureStorageProvider);
      _cachedToken = await storage.read(key: AppConstants.tokenKey);
      _isTokenLoaded = true;
    }

    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $_cachedToken';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final responseBody = err.response?.data?.toString() ?? '';
    
    if (statusCode == 502 || statusCode == 503 || statusCode == 530 ||
        responseBody.contains('tunnel') && responseBody.contains('refused') ||
        responseBody.contains('failed to connect to origin')) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: NetworkException(message: 'backendOffline'),
        )
      );
      return;
    }

    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/api/Auth/')) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: UnauthorizedException(message: 'sessionExpired'),
        )
      );
      return;
    }
    
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: NetworkException(message: 'networkError'),
        )
      );
      return;
    }
    
    handler.next(err);
  }
}
