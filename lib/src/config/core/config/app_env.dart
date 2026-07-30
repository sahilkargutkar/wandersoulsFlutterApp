import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._(); // prevent instantiation

  static String get googleMapApiKey => dotenv.env['GOOGLE_API_KEY'] ?? '';

  // static bool get enableLogs =>
  //     dotenv.env['ENABLE_LOGS'] == 'true';

  // static String get environment =>
  //     dotenv.env['APP_ENV'] ?? 'unknown';
}
