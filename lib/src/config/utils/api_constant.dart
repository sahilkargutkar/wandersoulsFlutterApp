import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "https://wandersouls.azurewebsites.net/api";
  static const String mapURL = "https://maps.googleapis.com/";
  static String get googleMapApiKey => dotenv.env["GOOGLE_API_KEY"] ?? "";

  // AI Service
  static String get aiBaseUrl {
    if (kIsWeb) {
      return "http://localhost:8000"; // Web browser
    }
    return "http://10.0.2.2:8000"; // Android emulator
  }
  static const String generateItinerary = "/generate-itinerary";

  //Auth
  static const String login = "/User/login";
  static const String createTrip = "/Trips/create-trip";
  static const String getTrips = "/Trips";
  static const String register = "/User/register";

  // static String deleteUser(String userId) => "/api/User/$userId";
  static String userById(String userId) => "/User/$userId";
}
