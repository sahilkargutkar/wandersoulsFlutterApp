import 'package:flutter/foundation.dart';
import 'package:wonder_souls/src/config/core/injector/injector.dart';
import 'package:wonder_souls/src/config/core/services/google_places_new_service.dart';
import 'package:wonder_souls/src/features/trips/model/trip.dart';

class TripImageHelper {
  TripImageHelper._();

  static final Map<String, String> _googlePlacesCache = {};

  static String? getCachedPhoto(String destination) {
    final key = destination.trim().toLowerCase();
    if (key.isEmpty) return null;
    return _googlePlacesCache[key];
  }

  static String getDisplayImageUrl(TripData trip) {
    if (trip.imageUrl.contains("places.googleapis.com") ||
        trip.imageUrl.contains("maps.googleapis.com")) {
      return trip.imageUrl;
    }
    final destKey = trip.mainDestination.trim().isNotEmpty
        ? trip.mainDestination.trim().toLowerCase()
        : trip.name.trim().toLowerCase();
    if (destKey.isNotEmpty && _googlePlacesCache.containsKey(destKey)) {
      return _googlePlacesCache[destKey]!;
    }
    return trip.imageUrl;
  }

  static Future<String?> resolvePhoto(String destination) async {
    final key = destination.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_googlePlacesCache.containsKey(key)) {
      return _googlePlacesCache[key];
    }

    try {
      final placesService = sl.isRegistered<GooglePlacesNewService>()
          ? sl<GooglePlacesNewService>()
          : GooglePlacesNewService();

      final placeId = await placesService.searchPlaceId(destination);
      if (placeId != null && placeId.isNotEmpty) {
        final details = await placesService.getPlaceDetails(placeId);
        final photos = details?["photos"] as List?;
        if (photos != null && photos.isNotEmpty) {
          final photoName = photos.first["name"];
          if (photoName != null) {
            final uri = await placesService.getPhotoUri(photoName);
            if (uri != null && uri.isNotEmpty) {
              _googlePlacesCache[key] = uri;
              return uri;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("TripImageHelper: error resolving Google Places photo for $destination: $e");
    }
    return null;
  }
}
