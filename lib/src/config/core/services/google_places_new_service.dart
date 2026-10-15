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
        "https://places.googleapis.com/v1/places:searchText",
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
        "https://places.googleapis.com/v1/places/$placeId",
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
      final cleanName = photoName.startsWith('/') ? photoName.substring(1) : photoName;
      final response = await _dio.get(
        "https://places.googleapis.com/v1/$cleanName/media",
        queryParameters: {
          "maxWidthPx": 800,
          "maxHeightPx": 600,
          "skipHttpRedirect": true,
          "key": apiKey,
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

  /// Build direct photo URL using photo resource name
  String buildDirectPhotoUrl(String photoName, {int maxWidthPx = 800, int maxHeightPx = 600}) {
    final cleanName = photoName.startsWith('/') ? photoName.substring(1) : photoName;
    return "https://places.googleapis.com/v1/$cleanName/media?maxWidthPx=$maxWidthPx&maxHeightPx=$maxHeightPx&key=$apiKey";
  }

  /// Search places using text query with country/region code filter and return rich spot suggestions
  Future<List<Map<String, dynamic>>> searchPlacesByText(
    String query, {
    String? regionCode,
    int pageSize = 12,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "textQuery": query,
        "pageSize": pageSize,
      };

      if (regionCode != null && regionCode.trim().isNotEmpty) {
        body["regionCode"] = regionCode.trim().toUpperCase();
      }

      final response = await _dio.post(
        "https://places.googleapis.com/v1/places:searchText",
        data: jsonEncode(body),
        options: Options(
          headers: {
            "X-Goog-Api-Key": apiKey,
            "X-Goog-FieldMask":
                "places.id,places.displayName,places.formattedAddress,places.rating,places.userRatingCount,places.photos,places.types,places.location",
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final placesList = response.data["places"] as List?;
        if (placesList != null && placesList.isNotEmpty) {
          return placesList.map((p) {
            final map = p as Map<String, dynamic>;
            final displayName = (map["displayName"] is Map)
                ? (map["displayName"]["text"] ?? "").toString()
                : "";
            final photos = map["photos"] as List?;
            String? photoUrl;
            if (photos != null && photos.isNotEmpty) {
              final firstPhotoName = photos[0]["name"] as String?;
              if (firstPhotoName != null) {
                photoUrl = buildDirectPhotoUrl(firstPhotoName);
              }
            }

            final location = map["location"] as Map<String, dynamic>?;
            final double? lat = (location?["latitude"] as num?)?.toDouble();
            final double? lng = (location?["longitude"] as num?)?.toDouble();

            final types = (map["types"] as List?)?.cast<String>() ?? [];

            return {
              "id": map["id"] ?? "",
              "name": displayName,
              "address": map["formattedAddress"] ?? "",
              "rating": (map["rating"] as num?)?.toDouble() ?? 4.5,
              "userRatingCount": (map["userRatingCount"] as num?)?.toInt() ?? 100,
              "types": types,
              "photoUrl": photoUrl,
              "lat": lat,
              "lng": lng,
            };
          }).where((p) => (p["name"] as String).isNotEmpty).toList();
        }
      }
    } catch (e) {
      debugPrint("Error searching places by text: $e");
    }
    return [];
  }
}
