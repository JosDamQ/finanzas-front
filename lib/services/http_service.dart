import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HttpService {
  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  HttpService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_URL'] ?? 'http://localhost:3200/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          String errorMessage = 'Ocurrió un error inesperado';

          if (e.response != null) {
            if (e.response?.data != null) {
              try {
                final data = e.response?.data;
                if (data is Map && data.containsKey('message')) {
                  errorMessage = data['message'];
                } else if (data is String) {
                  // Sometimes backend sends plain text
                  errorMessage = data;
                } else {
                  // Fallback to status message
                  errorMessage =
                      e.response?.statusMessage ?? e.message ?? errorMessage;
                }
              } catch (_) {
                errorMessage = e.response?.statusMessage ?? errorMessage;
              }
            } else {
              errorMessage = e.response?.statusMessage ?? errorMessage;
            }
          } else {
            // No response (timeout, network error)
            errorMessage = e.message ?? errorMessage;
          }

          // Re-throw with custom message attached to 'error' property
          // Note: UI usually reads e.error or e.message
          return handler.next(
            DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: errorMessage, // This is what we catch in UI usually
              message: errorMessage,
            ),
          );
        },
      ),
    );
  }

  Dio get client => _dio;
}
