import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get apiURL => _get('API_URL');

  static String _get(String key) {
    return dotenv.env[key] ?? '';
  }

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}
