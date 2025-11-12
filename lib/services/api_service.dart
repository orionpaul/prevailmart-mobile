import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

/// API Service - HTTP Client for all API calls
class ApiService {
  late final Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30), // Optimized timeout
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    print('🚀 API Service initialized');
    print('📍 Base URL: ${ApiConfig.baseUrl}');

    // Add retry interceptor
    _dio.interceptors.add(_RetryInterceptor(dio: _dio, retries: 3));

    // Add interceptors for logging and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Always reload token from storage to ensure it's fresh
        _token = await storageService.getSecure(ApiConfig.tokenKey);

        // Add token to all requests if available
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
          print('🌐 ${options.method} ${options.path} (🔑 Token: ${_token!.substring(0, 20)}...)');
        } else {
          print('🌐 ${options.method} ${options.path} (⚠️ No token)');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ ${response.statusCode} ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.response?.statusCode} ${error.message}');
        return handler.next(error);
      },
    ));
  }

  /// Save token to secure storage
  Future<void> saveToken(String token) async {
    _token = token;
    await storageService.saveSecure(ApiConfig.tokenKey, token);
    print('💾 Token saved securely');
  }

  /// Remove token from storage
  Future<void> removeToken() async {
    _token = null;
    await storageService.deleteSecure(ApiConfig.tokenKey);
    print('🗑️ Token removed');
  }

  /// GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH Request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  String _handleError(DioException error) {
    String errorMessage = 'Something went wrong';

    if (error.response != null) {
      // Server responded with error
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (statusCode == 401) {
        errorMessage = 'Unauthorized. Please login again.';
        // Clear invalid token
        _handleUnauthorized();
      } else if (statusCode == 404) {
        errorMessage = 'Resource not found';
      } else if (statusCode == 500) {
        errorMessage = 'Server error. Please try again later.';
      }
    } else {
      // Network or other errors
      if (error.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check:\n1. Backend server is running\n2. Correct IP address in API config\n3. Device can reach server';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server response timeout. Server may be slow or overloaded.';
      } else if (error.type == DioExceptionType.unknown) {
        errorMessage = 'Network error. Check internet connection and server accessibility.';
      } else if (error.type == DioExceptionType.cancel) {
        errorMessage = 'Request was cancelled';
      }
    }

    return errorMessage;
  }

  /// Handle 401 Unauthorized - Clear token
  void _handleUnauthorized() {
    print('🔐 401 Unauthorized - Clearing invalid token');
    _token = null;
    // Clear from storage asynchronously
    storageService.deleteSecure(ApiConfig.tokenKey);
    storageService.deleteSecure(ApiConfig.userKey);
  }
}

/// Retry Interceptor - Automatically retries failed requests
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final Duration retryDelay;

  _RetryInterceptor({
    required this.dio,
    this.retries = 2,  // Reduced to 2 retries
    this.retryDelay = const Duration(seconds: 1), // Reduced delay
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retriesLeft = extra['retries'] ?? retries;

    // Don't retry on authentication errors or client errors
    if (err.response?.statusCode != null && err.response!.statusCode! < 500) {
      return handler.next(err);
    }

    // Don't retry connection timeouts to avoid long waits
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      print('⏱️ Timeout error - not retrying');
      return handler.next(err);
    }

    // Don't retry if no retries left
    if (retriesLeft <= 0) {
      return handler.next(err);
    }

    print('🔄 Network error, retrying... (Attempt ${retries - retriesLeft + 1}/$retries)');
    print('   Error: ${err.type} - ${err.message}');

    // Wait before retrying
    await Future.delayed(retryDelay);

    // Create new request with decremented retries
    final options = err.requestOptions;
    options.extra['retries'] = retriesLeft - 1;

    try {
      // Retry the request
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      // If retry also fails, pass the error to the next interceptor
      return handler.next(e);
    }
  }
}

/// Singleton instance
final apiService = ApiService();
