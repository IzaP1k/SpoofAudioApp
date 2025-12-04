import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/xai_analyse/xaiScreen.dart';
import 'package:on_popup_window_widget/on_popup_window_widget.dart';
import 'package:on_process_button_widget/on_process_button_widget.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> sendAudioToBackend(String audioPath) async {
  var uri = Uri.parse("$baseUrl/analyse_audio/");
  var request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath('audio', audioPath));

  var response = await request.send();

  if (response.statusCode == 200) {
    var respStr = await response.stream.bytesToString();
    return Map<String, dynamic>.from(jsonDecode(respStr));
  } else {
    throw Exception("Błąd wysyłania audio: ${response.statusCode}");
  }
}

class PopMenuClass {
  static Future<void> show(
    BuildContext context, {
    int intend = 0,
    final Map<String, dynamic>? heatmap_base64,
  }) async {
    return showDialog(
      context: context,
      builder: (context) {
        return OnPopupWindowWidget(
          biggerMaxSize: 2000,
          intend: intend,
          title: const Text("Opcje"),
          overlapChildren: [
            Positioned(
              right: -2,
              top: -2,
              child: OnProcessButtonWidget(
                contentPadding: EdgeInsets.zero,
                onDone: (_) => Navigator.of(context).pop(),
                backgroundColor: kPrimaryColor,
                child: const Icon(Icons.cancel, color: Colors.white),
              ),
            ),
          ],
          child: heatmap_base64 == null
              ? const Center(child: Text("Brak heatmap"))
              : SingleChildScrollView(
                  child: Column(
                    children: heatmap_base64.entries.map((entry) {
                      final heatmapData = entry.value;
                      final String base64String = heatmapData["heatmap"];
                      final Map<String, dynamic> topFeatures =
                          heatmapData["top_features"];

                      Uint8List bytes = base64Decode(base64String);

                      String strongestText = "";
                      String weakestText = "";

                      if (topFeatures.containsKey("strongest")) {
                        strongestText = (topFeatures["strongest"] as List)
                            .map((e) => "${e['feature']}: ${e['strength']}")
                            .join(", ");
                      }

                      if (topFeatures.containsKey("weakest")) {
                        weakestText = (topFeatures["weakest"] as List)
                            .map((e) => "${e['feature']}: ${e['strength']}")
                            .join(", ");
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Image.memory(bytes, fit: BoxFit.contain),
                            const SizedBox(height: 5),
                            Text(
                              "Strongest: $strongestText",
                              style: const TextStyle(color: Colors.green),
                            ),
                            Text(
                              "Weakest: $weakestText",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        );
      },
    );
  }
}
