import 'package:geolocator/geolocator.dart';

class LocationHelper {
  Future<Position> getCurrentLocation() async {
    // 1️⃣ Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // 2️⃣ Check permission
    LocationPermission permission = await Geolocator.checkPermission();

    // 3️⃣ Request permission if denied
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    // 4️⃣ Permission denied forever
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied, please enable from settings',
      );
    }

    // 5️⃣ Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
