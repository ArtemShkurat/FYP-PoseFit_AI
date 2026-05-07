import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:5000';
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
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await storage.write(key: 'isLoggedIn', value: 'true');
      await storage.write(key: 'userId', value: data['user']['id'].toString());
      await storage.write(key: 'username', value: data['user']['username']);
      await storage.write(key: 'email', value: data['user']['email']);
      await storage.write(
        key: 'mustChangePassword',
        value: data['user']['must_change_password'].toString(),
      );
    }

    return data;
  }

  static Future<bool> isLoggedIn() async {
    final value = await storage.read(key: 'isLoggedIn');
    return value == 'true';
  }

  static Future<String?> getUserId() async {
    return await storage.read(key: 'userId');
  }

  static Future<String?> getUsername() async {
    return await storage.read(key: 'username');
  }

  static Future<String?> getEmail() async {
    return await storage.read(key: 'email');
  }

  static Future<String?> getMustChangePassword() async {
    return await storage.read(key: 'mustChangePassword');
  }

  static Future<void> logout() async {
    await storage.deleteAll();
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    final userId = await storage.read(key: 'userId');

    if (userId == null) {
      return {'success': false, 'message': 'No logged in user found.'};
    }

    final response = await http.post(
      Uri.parse('$baseUrl/delete-account'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': int.parse(userId)}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await storage.deleteAll();
    }

    return data;
  }

  static Future<Map<String, dynamic>> updateUsername({
    required String username,
  }) async {
    final userId = await storage.read(key: 'userId');

    if (userId == null) {
      return {'success': false, 'message': 'No logged in user found.'};
    }

    final response = await http.post(
      Uri.parse('$baseUrl/update-username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': int.parse(userId), 'username': username}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      await storage.write(key: 'username', value: data['username']);
    }

    return data;
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userId = await storage.read(key: 'userId');

    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': int.parse(userId!),
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendSupportMessage({
    required String subject,
    required String message,
  }) async {
    final username = await getUsername();
    final email = await getEmail();

    final response = await http.post(
      Uri.parse('$baseUrl/support-message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'user_email': email,
        'subject': subject,
        'message': message,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),

      headers: {'Content-Type': 'application/json'},

      body: jsonEncode({'email': email}),
    );

    return jsonDecode(response.body);
  }
}
