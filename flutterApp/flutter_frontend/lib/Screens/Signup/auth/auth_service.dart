import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_frontend/constants.dart';

class AuthService {
  Future<String?> register(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) async {
    if (password != confirmPassword) {
      throw {
        "password": ["Hasła nie są takie same."],
      };
    }

    final url = Uri.parse("$baseUrl/auth/register/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    }

    if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw error;
    }

    throw {
      "error": ["Wystąpił błąd po stronie serwera."],
    };
  }
}
