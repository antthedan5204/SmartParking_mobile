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

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: AppConstants.tokenKey);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Phát hiện tunnel offline (Cloudflare Tunnel, hoặc tunnel khác)
    final statusCode = err.response?.statusCode;
    final responseBody = err.response?.data?.toString() ?? '';
    if (statusCode == 502 || statusCode == 503 || statusCode == 530 ||
        responseBody.contains('tunnel') && responseBody.contains('refused') ||
        responseBody.contains('failed to connect to origin')) {
      throw NetworkException(
        message:
            'Backend đang offline hoặc tunnel chưa được khởi động. '
            'Hãy kiểm tra lại cloudflared và backend server.',
      );
    }

    if (err.response?.statusCode == 401) {
      throw UnauthorizedException(message: 'Phiên đăng nhập đã hết hạn');
    }
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      throw NetworkException(message: 'Không thể kết nối đến máy chủ');
    }
    handler.next(err);
  }
}
