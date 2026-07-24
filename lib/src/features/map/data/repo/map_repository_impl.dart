import '../../domain/respo/map_repository.dart';
import '../datasource/map_remote_data_source.dart' show MapRemoteDataSource;

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource remote;

  MapRepositoryImpl(this.remote);

  @override
  Future<Map<String, dynamic>> getDirections(
    String origin,
    String destination,
  ) {
    return remote.getDirections(origin, destination);
  }

  @override
  Future<Map<String, dynamic>> getAutocomplete(String input) {
    return remote.getAutocomplete(input);
  }

  @override
  Future<Map<String, dynamic>> reverseGeocode(double lat, double lng) {
    return remote.reverseGeocode(lat, lng);
  }
}
