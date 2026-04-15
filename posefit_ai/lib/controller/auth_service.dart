import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://172.25.105.142:5000';
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await storage.write(key: 'isLoggedIn', value: 'true');
      await storage.write(key: 'userId', value: data['user']['id'].toString());
      await storage.write(key: 'username', value: data['user']['username']);
      await storage.write(key: 'email', value: data['user']['email']);
    }

    return data;
  }

  static Future<bool> isLoggedIn() async {
    final value = await storage.read(key: 'isLoggedIn');
    return value == 'true';
  }

  static Future<void> logout() async {
    await storage.deleteAll();
  }
}