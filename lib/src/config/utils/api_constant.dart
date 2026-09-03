import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "https://wandersouls.azurewebsites.net/api";
  static const String mapURL = "https://maps.googleapis.com/";
  static String get googleMapApiKey => dotenv.env["GOOGLE_KEY"] ?? "";

  // AI Service
  static String get aiBaseUrl {
    if (kIsWeb) {
      return "http://localhost:8000"; // Web browser
    }
    return "http://10.0.2.2:8000"; // Android emulator
  }

  static const String generateItinerary = "/generate-itinerary";

  // Auth & User
  static const String login = "/User/login";
  static const String register = "/User/register";
  static const String getUsers = "/User";
  static const String verifyEmail = "/User/verify-email";
  static const String updatePassword = "/User/update-password";
  static String userById(String userId) => "/User/$userId";

  // Trips
  static const String createTrip = "/Trips/create-trip";
  static const String getTrips = "/Trips";
  static String tripById(String tripId) => "/Trips/$tripId";
  static const String uploadTripFile = "/Trips/upload";
  static const String downloadTripFile = "/Trips/download";

  // Accomodation
  static const String accomodations = "/Accomodation";
  static String accomodationById(String id) => "/Accomodation/$id";

  // TripTransports
  static const String tripTransports = "/TripTransports";
  static String tripTransportById(String id) => "/TripTransports/$id";

  // Destinations
  static const String destinations = "/Destinations";
  static String destinationById(String id) => "/Destinations/$id";
  static const String createDestination = "/Destinations/create-destination";

  // Locations
  static const String locations = "/Locations";
  static String locationById(String id) => "/Locations/$id";

  // TripActivity
  static const String tripActivities = "/TripActivity";
  static String tripActivityById(String id) => "/TripActivity/$id";

  // TripBudget & Expenses
  static const String tripBudgetGetAllExpenses = "/TripBudget/GetAllExpenses";
  static const String tripBudgetExpenses = "/TripBudget/expenses";
  static String tripBudgetExpenseById(String expenseId) => "/TripBudget/expenses/$expenseId";

  // Preference
  static const String getPreference = "/Preference";
  static const String savePreference = "/Preference/save";
  static const String updatePreference = "/Preference/update";

  // Other / Legal
  static const String otherService = "/OtherService";
}
