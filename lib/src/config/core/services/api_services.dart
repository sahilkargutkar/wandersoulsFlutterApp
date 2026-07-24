import 'package:dio/dio.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';
import '../../model/api_result.dart';
import '../../model/failure.dart';
import '../../model/success.dart';
import '../local_storage/token_storage.dart';

class ApiService {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final String baseURL;

  ApiService(this._tokenStorage, {required this.baseURL})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseURL,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      ) {
    _addInterceptor();
  }

  // ===============================
  // INTERCEPTOR
  // ===============================
  void _addInterceptor() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired or invalid
            await _tokenStorage.clearToken();
            // Optional: trigger logout event here
          }

          return handler.next(error);
        },
      ),
    );

    // Optional: logging
    _dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  // ===============================
  // GET
  // ===============================
  Future<ApiResult<T>> get<T>(
    String path, {
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.get(path);
      return Success<T>(fromJson(response.data));
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ===============================
  // POST
  // ===============================
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return Success<T>(fromJson(response.data));
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ===============================
  // DELETE
  // ===============================

  Future<ApiResult<T>> delete<T>(
    String path, {
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.delete(path);
      return Success<T>(fromJson(response.data));
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  // ===============================
  // PUT
  // ===============================
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return Success<T>(fromJson(response.data));
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Failure<T> _handleError<T>(DioException e) {
    return Failure<T>(
      message: e.response?.data["message"] ?? "Server error",
      statusCode: e.response?.statusCode,
    );
  }
}
