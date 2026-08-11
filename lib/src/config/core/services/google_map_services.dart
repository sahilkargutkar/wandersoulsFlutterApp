import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/model/failure.dart';

class GoogleMapsApiService {
  final Dio dio;
  final String apiKey;
  final String baseURL;

  GoogleMapsApiService({required this.apiKey, required this.baseURL})
    : dio = Dio(
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
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  Future<Either<Failure, List<PlaceModel>>> searchPlaces(String query) async {
    try {
      final response = await dio.get(
        "maps/api/place/autocomplete/json",
        queryParameters: {"input": query, "key": apiKey},
      );

      final data = response.data;

      if (data == null || data["predictions"] == null) {
        return const Right([]);
      }

      final places = (data["predictions"] as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();

      return Right(places);
    } on DioException catch (e) {
      return Left(Failure(message: e.message ?? "Network error"));
    } catch (e) {
      return const Left(Failure(message: "Unexpected error"));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getDirections(
    String origin,
    String destination,
  ) async {
    try {
      final response = await dio.get(
        "directions/json",
        queryParameters: {
          "origin": origin,
          "destination": destination,
          "key": apiKey,
        },
      );

      return Right(response.data);
    } on DioException catch (e) {
      return Left(Failure(message: e.message ?? "Directions error"));
    } catch (e) {
      return const Left(Failure(message: "Unexpected error"));
    }
  }

  Future<Map<String, dynamic>> getRequest(
    String path,
    Map<String, dynamic> queryParameters,
  ) async {
    try {
      final response = await dio.get(path, queryParameters: queryParameters);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
