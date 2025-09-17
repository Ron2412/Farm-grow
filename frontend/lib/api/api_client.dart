import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  // Dynamic base URL based on platform
  static String get _baseUrl {
    if (kIsWeb) {
      // Web app
      return "http://localhost:8000";
    } else if (Platform.isAndroid) {
      // Android emulator
      return "http://10.0.2.2:8000";
    } else if (Platform.isIOS) {
      // iOS simulator
      return "http://localhost:8000";
    } else {
      // Desktop (macOS, Windows, Linux)
      return "http://localhost:8000";
    }
  }

  // A static method to handle GET requests
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final Uri url = Uri.parse("$_baseUrl$endpoint");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load data from endpoint: $endpoint. '
          'Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }

  // A static method to handle POST requests
  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final Uri url = Uri.parse("$_baseUrl$endpoint");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to post data to endpoint: $endpoint. '
          'Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
