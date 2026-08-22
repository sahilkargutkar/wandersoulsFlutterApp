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

  Future<Either<Failure, Map<String, double>>> getLatLngFromAddress(String address) async {
    try {
      // 1. Call Autocomplete API to get place_id (since Geocoding is restricted on some developer keys)
      final autocompleteResponse = await dio.get(
        "maps/api/place/autocomplete/json",
        queryParameters: {"input": address, "key": apiKey},
      );

      final autocompleteData = autocompleteResponse.data;
      if (autocompleteData != null &&
          autocompleteData["status"] == "OK" &&
          autocompleteData["predictions"] != null &&
          (autocompleteData["predictions"] as List).isNotEmpty) {
        
        final String placeId = autocompleteData["predictions"][0]["place_id"];

        // 2. Call Places Details API to get geometry coordinates
        final detailsResponse = await dio.get(
          "maps/api/place/details/json",
          queryParameters: {
            "place_id": placeId,
            "fields": "geometry",
            "key": apiKey,
          },
        );

        final detailsData = detailsResponse.data;
        if (detailsData != null &&
            detailsData["status"] == "OK" &&
            detailsData["result"] != null &&
            detailsData["result"]["geometry"] != null) {
          
          final location = detailsData["result"]["geometry"]["location"];
          final double lat = (location["lat"] as num).toDouble();
          final double lng = (location["lng"] as num).toDouble();

          return Right({"lat": lat, "lng": lng});
        }
      }

      // 3. Fallback to standard Geocoding API if Autocomplete/Details failed
      final response = await dio.get(
        "maps/api/geocode/json",
        queryParameters: {"address": address, "key": apiKey},
      );

      final data = response.data;
      if (data == null || data["status"] != "OK" || data["results"] == null) {
        return const Left(Failure(message: "Location not found"));
      }

      final results = data["results"] as List;
      if (results.isEmpty) {
        return const Left(Failure(message: "Location not found"));
      }

      final location = results.first["geometry"]["location"];
      final double lat = (location["lat"] as num).toDouble();
      final double lng = (location["lng"] as num).toDouble();

      return Right({"lat": lat, "lng": lng});
    } on DioException catch (e) {
      return Left(Failure(message: e.message ?? "Network error"));
    } catch (e) {
      return const Left(Failure(message: "Unexpected error"));
    }
  }
}
