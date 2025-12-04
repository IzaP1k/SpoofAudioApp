import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/constants.dart';

class AuthService {
  Future<String?> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/api-token-auth/");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        return token;
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Uri.parse("$baseUrl/auth/change-password/");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Token $token",
        },
        body: jsonEncode({
          "old_password": oldPassword,
          "new_password": newPassword,
          "confirm_password": confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }
        return null;
      } else {
        if (data is Map && data.values.first is List) {
          return data.values.first[0];
        } else if (data["error"] != null) {
          return data["error"];
        } else {
          return "Nie udało się zmienić hasła.";
        }
      }
    } catch (e) {
      return "Błąd połączenia z serwerem.";
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
