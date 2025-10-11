import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<String?> register(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) async {
    if (password != confirmPassword) {
      throw Exception("Hasła nie są takie same");
    }

    final url = Uri.parse("$baseUrl/auth/register/");
    try {
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
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error);
      }
    } catch (e) {
      rethrow;
    }
  }
}
