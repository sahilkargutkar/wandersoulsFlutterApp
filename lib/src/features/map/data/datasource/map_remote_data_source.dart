import '../../../../config/core/services/google_map_services.dart';


class MapRemoteDataSource {
  final GoogleMapsApiService service;
  final String apiKey;

  MapRemoteDataSource({required this.service, required this.apiKey});

  Future<Map<String, dynamic>> getDirections(
    String origin,
    String destination) {
    return service.getRequest("directions/json", {
      "origin": origin,
      "destination": destination,
      "key": apiKey,
    });
  }

  Future<Map<String, dynamic>> getAutocomplete(String input) {
    return service.getRequest("place/autocomplete/json", {
      "input": input,
      "key": apiKey,
    });
  }

  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) {
    return service.getRequest("geocode/json", {
      "latlng": "$lat,$lng",
      "key": apiKey,
    });
  }
}
