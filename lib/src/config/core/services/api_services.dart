import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';

import '../../model/api_result.dart';
import '../../model/failure.dart';
import '../../model/success.dart';
import '../local_storage/token_storage.dart';

class ApiService {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final String baseURL;

  /// Called when the session expires (401 response).
  /// The router should listen to this and redirect to login.
  /// Set after construction once the router is built.
  void Function()? onSessionExpired;

  ApiService(this._tokenStorage, {required this.baseURL, this.onSessionExpired})
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
          debugPrint("API Request: path=${options.path}, hasToken=${token != null}");

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          debugPrint("API Error: path=${error.requestOptions.path}, statusCode=${error.response?.statusCode}, message=${error.message}");
          if (error.response?.statusCode == 401 &&
              error.requestOptions.path != ApiConstants.login) {
            debugPrint("Session expired (401), clearing token and triggering redirect");
            await _tokenStorage.clearToken();
            onSessionExpired?.call();
          }

          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
        ),
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
    String? message;

    if (responseData is Map<String, dynamic>) {
      if (responseData["message"] != null &&
          responseData["message"].toString().isNotEmpty) {
        message = responseData["message"].toString();
      } else if (responseData["errors"] is Map<String, dynamic>) {
        final errorsMap = responseData["errors"] as Map<String, dynamic>;
        final errorList = <String>[];
        errorsMap.forEach((key, val) {
          if (val is List) {
            errorList.addAll(val.map((e) => e.toString()));
          } else if (val != null) {
            errorList.add(val.toString());
          }
        });
        if (errorList.isNotEmpty) {
          message = errorList.join(", ");
        } else if (responseData["title"] != null) {
          message = responseData["title"].toString();
        }
      } else if (responseData["title"] != null) {
        message = responseData["title"].toString();
      }
    } else if (responseData != null) {
      message = responseData.toString();
    }

    return Failure<T>(
      message: message == null || message.isEmpty ? (e.message ?? "Server error") : message,
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
      final response = await _dio.put(
        path,
        queryParameters: queryParameters,
        data: data,
      );
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

      final response = await _dio.post("/Trips/upload", data: formData);

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

  // ===============================
  // AI SERVICE (separate base URL)
  // ===============================

  /// POST to the AI microservice (different base URL than the main API).
  Future<ApiResult<Map<String, dynamic>>> aiPost(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final aiDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.aiBaseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      );

      if (kDebugMode) {
        aiDio.interceptors.add(
          LogInterceptor(requestBody: true, responseBody: true),
        );
      }

      final response = await aiDio.post(path, data: data);
      if (response.statusCode == 200) {
        return Success<Map<String, dynamic>>(
          response.data as Map<String, dynamic>,
        );
      }
      return Failure<Map<String, dynamic>>(
        message: "AI service returned ${response.statusCode}",
      );
    } on DioException catch (e) {
      return Failure<Map<String, dynamic>>(
        message: e.message ?? "AI service unavailable",
      );
    } catch (e) {
      return Failure<Map<String, dynamic>>(message: "AI service error: $e");
    }
  }
}
