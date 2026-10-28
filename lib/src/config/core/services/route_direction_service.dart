import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonder_souls/src/config/utils/api_constant.dart';

class RouteDirectionService {
  RouteDirectionService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static final Map<String, List<LatLng>> _cache = {};

  /// Fetches a road-following route connecting the given destination waypoints.
  /// First attempts Google Directions API if an API key is present.
  /// If that is unavailable or fails, falls back to OSRM (Open Source Routing Machine).
  /// If all fail, falls back to the direct straight points.
  static Future<List<LatLng>> fetchRoadRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return waypoints;

    final cacheKey = waypoints
        .map((p) =>
            "${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}")
        .join(";");

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 1. Try Google Directions API first (if API key available)
    final googleKey = ApiConstants.googleMapApiKey;
    if (googleKey.isNotEmpty) {
      try {
        final origin =
            "${waypoints.first.latitude},${waypoints.first.longitude}";
        final destination =
            "${waypoints.last.latitude},${waypoints.last.longitude}";

        final queryParams = <String, dynamic>{
          "origin": origin,
          "destination": destination,
          "key": googleKey,
          "mode": "driving",
        };

        if (waypoints.length > 2) {
          final middlePoints = waypoints
              .sublist(1, waypoints.length - 1)
              .map((p) => "${p.latitude},${p.longitude}")
              .join("|");
          queryParams["waypoints"] = middlePoints;
        }

        final response = await _dio.get(
          "https://maps.googleapis.com/maps/api/directions/json",
          queryParameters: queryParams,
        );

        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data["status"] == "OK" &&
              data["routes"] is List &&
              (data["routes"] as List).isNotEmpty) {
            final route = data["routes"][0];
            final overviewPolyline =
                route["overview_polyline"]?["points"] as String?;
            if (overviewPolyline != null && overviewPolyline.isNotEmpty) {
              final decoded = _decodePolyline(overviewPolyline);
              if (decoded.length >= 2) {
                _cache[cacheKey] = decoded;
                return decoded;
              }
            }
          }
        }
      } catch (_) {
        // Fall through to OSRM fallback
      }
    }

    // 2. Fallback to OSRM Driving Router (free, global, no API key needed)
    try {
      final coordString = waypoints
          .map((p) => "${p.longitude},${p.latitude}")
          .join(";");

      final url =
          "https://router.project-osrm.org/route/v1/driving/$coordString?overview=full&geometries=geojson";

      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        if (data["code"] == "Ok" &&
            data["routes"] is List &&
            (data["routes"] as List).isNotEmpty) {
          final route = data["routes"][0];
          final geometry = route["geometry"];
          if (geometry != null && geometry["coordinates"] is List) {
            final coords = geometry["coordinates"] as List;
            final List<LatLng> roadPoints = [];
            for (final c in coords) {
              if (c is List && c.length >= 2) {
                final lng = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                roadPoints.add(LatLng(lat, lng));
              }
            }
            if (roadPoints.length >= 2) {
              _cache[cacheKey] = roadPoints;
              return roadPoints;
            }
          }
        }
      }
    } catch (_) {
      // Fall through to straight-line fallback
    }

    // 3. Fallback to original straight waypoints
    return waypoints;
  }

  /// Decodes Google's Encoded Polyline algorithm into a List of LatLng
  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}
