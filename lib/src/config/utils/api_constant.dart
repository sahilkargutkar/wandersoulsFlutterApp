class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "https://wandersouls.azurewebsites.net/api";
  static const String mapURL = "https://maps.googleapis.com/";


  //Auth
  static const String login = "/User/login";
  static const String trips = "/Trips";
  static const String register = "User/register";

  // static String deleteUser(String userId) => "/api/User/$userId";
  static String userById(String userId) => "/User/$userId";

}
