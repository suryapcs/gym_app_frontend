import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class AuthService {
  static const String tokenKey = 'token';

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success' && data['token'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(tokenKey, data['token']);
            return true;
          } else {
             throw Exception(data['message'] ?? 'Login failed');
          }
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Invalid server response. Please check server logs or database connection.');
          }
          rethrow;
        }
      } else {
         throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Invalid server response')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Failed to connect: $e');
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            return true;
          } else {
             throw Exception(data['message'] ?? 'Registration failed');
          }
        } catch (e) {
          if (e is FormatException) {
            throw Exception('Invalid server response. Please check server logs or database connection.');
          }
          rethrow;
        }
      } else {
         throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Invalid server response')) {
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
      throw Exception('Failed to connect: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(tokenKey);
  }
}
