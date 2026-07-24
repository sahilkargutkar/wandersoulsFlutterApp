abstract class MapRepository {
  Future<Map<String, dynamic>> getDirections(String origin, String destination);

  Future<Map<String, dynamic>> getAutocomplete(String input);

  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng);
}
