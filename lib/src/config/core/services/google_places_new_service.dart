import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:wonder_souls/src/config/utils/api_constant.dart';
 
class GooglePlacesNewService {
  final Dio _dio;
  String get apiKey => ApiConstants.googleMapApiKey;

  GooglePlacesNewService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: "https://places.googleapis.com/v1",
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      );

  /// Search for a place ID using a text query
  Future<String?> searchPlaceId(String query) async {
    try {
      final response = await _dio.post(
        "/places:searchText",
        data: jsonEncode({"textQuery": query, "pageSize": 1}),
        options: Options(
          headers: {"X-Goog-Api-Key": apiKey, "X-Goog-FieldMask": "places.id"},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final places = response.data["places"] as List?;
        if (places != null && places.isNotEmpty) {
          return places[0]["id"] as String?;
        }
      }
    } catch (e) {
      debugPrint("Error searching place ID: $e");
    }
    return null;
  }

  /// Fetch rich place details by place ID
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        "/places/$placeId",
        options: Options(
          headers: {
            "X-Goog-Api-Key": apiKey,
            "X-Goog-FieldMask":
                "id,displayName,formattedAddress,rating,userRatingCount,photos,editorialSummary,generativeSummary,websiteUri,internationalPhoneNumber,regularOpeningHours,currentOpeningHours,goodForChildren,goodForGroups,parkingOptions,accessibilityOptions",
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Error getting place details: $e");
    }
    return null;
  }

  /// Resolve photo URI using photo resource name
  Future<String?> getPhotoUri(String photoName) async {
    try {
      final response = await _dio.get(
        "/$photoName/media",
        queryParameters: {
          "maxWidthPx": 800,
          "maxHeightPx": 600,
          "skipHttpRedirect": true,
        },
        options: Options(headers: {"X-Goog-Api-Key": apiKey}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data["photoUri"] as String?;
      }
    } catch (e) {
      debugPrint("Error getting photo URI: $e");
    }
    return null;
  }
}
