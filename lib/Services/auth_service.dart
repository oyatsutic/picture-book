import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api'; // Update with your Node.js backend URL

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to server');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Failed to connect to server');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}