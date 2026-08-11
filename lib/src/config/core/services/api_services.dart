
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/route/app_routes.dart';
import 'package:wonder_souls/src/features/auth/presentation/screens/login_screen.dart';
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
          if (error.response?.statusCode == 401 && error.requestOptions.path != ApiConstants.login) {
            // Token expired or invalid
            await _tokenStorage.clearToken();
            router.go(LoginScreen.routeName);
          }

          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }
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
    final responseData = e.response?.data;
    final message = responseData is Map<String, dynamic>
        ? responseData["message"]?.toString()
        : responseData?.toString();

    return Failure<T>(
      message: message == null || message.isEmpty ? "Server error" : message,
      statusCode: e.response?.statusCode,
    );
  }

  Future<Either<Failure, List<PlaceModel>>> getLocations(
    int? pageNumber,
    int? pageSize,
    String search,
  ) async {
    try {
      final response = await _dio.get(
        "/Locations",
        queryParameters: {
          "pageNumber": pageNumber,
          "pageSize": pageSize,
          "search": search,
        },
      );

      final data = response.data;
      if (data == null || data["items"] == null) {
        return const Right([]);
      }

      final places = (data["items"] as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();

      return Right(places);
    } on DioException catch (e) {
      return Left(Failure(message: e.message ?? "Network error"));
    } catch (e) {
      return const Left(Failure(message: "Unexpected error"));
    }
  }

  // ===============================
  // QUERY PARAMS & MULTIPART FILE HELPERS
  // ===============================

  Future<ApiResult<T>> getWithParams<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return Success<T>(fromJson(response.data));
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResult<T>> putWithParams<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
    required T Function(dynamic data) fromJson,
  }) async {
    try {
      final response = await _dio.put(path, queryParameters: queryParameters, data: data);
      return Success<T>(fromJson(response.data));
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  Future<ApiResult<String>> uploadFile(String filePath, String blobPath) async {
    try {
      final formData = FormData.fromMap({
        "File": await MultipartFile.fromFile(filePath),
        "BlobPath": blobPath,
      });

      final response = await _dio.post(
        "/Trips/upload",
        data: formData,
      );

      return Success<String>(response.data?.toString() ?? "Uploaded");
    } on DioException catch (e) {
      return _handleError<String>(e);
    }
  }

  Future<ApiResult<String>> downloadFile(String blobPath) async {
    try {
      final response = await _dio.get(
        "/Trips/download",
        queryParameters: {"blobPath": blobPath},
      );

      return Success<String>(response.data?.toString() ?? "");
    } on DioException catch (e) {
      return _handleError<String>(e);
    }
  }
}
