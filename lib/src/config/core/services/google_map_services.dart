

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:wonder_souls/src/config/core/model/place_model.dart';
import 'package:wonder_souls/src/config/model/failure.dart';

class GoogleMapsApiService {
  final Dio dio;
  final String apiKey; 
  final String baseURL;

  GoogleMapsApiService({required this.apiKey,  required this.baseURL}) : dio = Dio(
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
  
    // Optional: logging
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  Future<Map<String, dynamic>> getRequest(
    String endpoint,
    Map<String, dynamic> queryParameters,
  ) async {
    final response = await dio.get(endpoint, queryParameters: queryParameters);
    return response.data;
  }

  Future<Either<Failure, List<PlaceModel>>> searchPlaces(String query) async {
    try {
      final response = await dio.get(
        "place/autocomplete/json",
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
      return Left(Failure(message:  e.message ?? "Network error"));
    } catch (e) {
      return const Left(Failure( message: "Unexpected error"));
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
      return Left(Failure( message:  e.message ?? "Directions error"));
    } catch (e) {
      return const Left(Failure(message: "Unexpected error"));
    }
  }
}
