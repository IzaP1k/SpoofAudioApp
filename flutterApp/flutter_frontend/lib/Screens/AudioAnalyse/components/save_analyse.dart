import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_frontend/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AnalysisService {
  static Future<http.Response> saveAnalysis({
    required String resultText,
    required String description,
    required String audioPath,
    required List<dynamic> instances,
    required List<dynamic> scores,
    bool deleteOldest = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final String selectedModel = prefs.getString('selected_model') ?? 'Res_Net';

    if (token == null)
      throw Exception("Brak tokenu — użytkownik nie jest zalogowany");

    final uri = Uri.parse("$baseUrl/analysis/save/");

    final audioBytes = await File(audioPath).readAsBytes();
    final audioBase64 = base64Encode(audioBytes);

    final body = jsonEncode({
      "result_text": resultText,
      "description": description,
      "audio_bytes": audioBase64,
      "instances": instances,
      "scores": scores,
      "model": selectedModel,
      "delete_oldest": deleteOldest,
    });

    return await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Token $token",
      },
      body: body,
    );
  }
}
