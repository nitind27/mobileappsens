import 'package:dio/dio.dart';
import '../services/storage_service.dart';

class DioClient {
  static Dio? _dio;

  static Dio get instance {
    if (_dio == null) {
      final baseUrl = StorageService.getBaseUrl();
      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Dynamically refresh base url in case user configured it
            options.baseUrl = StorageService.getBaseUrl();

            final token = StorageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) {
            String errorMessage = 'An unexpected network error occurred.';
            if (e.response != null) {
              final data = e.response?.data;
              if (data is Map && data['message'] != null) {
                errorMessage = data['message'].toString();
              } else if (e.response?.statusCode == 401) {
                errorMessage = 'Session expired. Please log in again.';
              } else if (e.response?.statusCode == 403) {
                errorMessage = 'Access denied: insufficient permissions.';
              } else if (e.response?.statusCode == 404) {
                errorMessage = 'The requested resource was not found.';
              } else if (e.response?.statusCode == 500) {
                errorMessage = 'Internal server error. Please try again later.';
              }
            } else if (e.type == DioExceptionType.connectionTimeout) {
              errorMessage = 'Connection timed out. Check your server connection.';
            } else if (e.type == DioExceptionType.connectionError) {
              errorMessage = 'Cannot reach server at ${StorageService.getBaseUrl()}. Ensure backend is running.';
            }

            final customError = DioException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: errorMessage,
            );
            return handler.next(customError);
          },
        ),
      );
    }
    return _dio!;
  }

  static void reset() {
    _dio = null;
  }
}
