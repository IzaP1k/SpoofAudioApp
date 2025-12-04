import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/Screens/AudioAnalyse/audioanalyse.dart';
import 'package:flutter_frontend/Screens/HistoryAnalyse/components/history_image.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/appbar.dart';
import 'package:flutter_frontend/Screens/Mainpage/main_page.dart';
import 'package:flutter_frontend/Screens/Settings/settings_screen.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/components/background.dart';

class HistoryScreen extends StatefulWidget {
  final List<dynamic> analysesData;

  const HistoryScreen({super.key, required this.analysesData});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<Map<String, dynamic>> analyses;

  @override
  void initState() {
    super.initState();
    analyses = widget.analysesData.asMap().entries.map((entry) {
      final index = entry.key;
      final record = entry.value;
      final createdAt = record['created_at'] ?? '';
      final dateParts = createdAt.split(' ')[0];
      return {
        "title":
            "Analiza ${index + 1} z dnia $dateParts - ${record['result_text'] ?? ''}",
        "id_history": record['id'],
        "result_text": record['result_text'],
        "description": record['description'],
        "audio_base64": record['audio_file'],
        "instances": record['instances'],
        "scores": record['scores'],
        'created_at': record['created_at'],
      };
    }).toList();
  }

  void removeAnalysis(String description) {
    setState(() {
      analyses.removeWhere((a) => a['description'] == description);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (analyses.isEmpty) {
      return Background(
        appBar: CustomAppBar(
          title: 'Detektor oszustw audio',
          backgroundColor: kPrimaryLightColor,
          detailsColor: kPrimaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(defaultPadding),
            child: Text(
              "Brak danych w historii użytkownika",
              style: TextStyle(fontSize: 18, color: kPrimaryColor),
            ),
          ),
        ),
      );
    }

    return Background(
      appBar: CustomAppBar(
        title: 'Historia analiz',
        backgroundColor: kPrimaryLightColor,
        detailsColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MainScreen()),
              );
            },
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(defaultPadding),
          child: Responsive(
            mobile: Column(
              children: [
                const HistoryImage(),
                const SizedBox(height: defaultPadding),
                ...analyses.map(
                  (analysis) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _AnalysisTile(
                      analysis: analysis,
                      onDeleteSuccess: removeAnalysis,
                    ),
                  ),
                ),
              ],
            ),
            desktop: Column(
              children: [
                const HistoryImage(),
                const SizedBox(height: defaultPadding),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: analyses
                      .map(
                        (analysis) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _AnalysisTile(
                              analysis: analysis,
                              onDeleteSuccess: removeAnalysis,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final Function(String)? onDeleteSuccess;

  const _AnalysisTile({required this.analysis, this.onDeleteSuccess});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    analysis["title"] ?? "",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kRejectionColor),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final token =
                        prefs.getString("auth_token") ?? "Brak tokena";

                    final confirm1 = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Usuwanie rekordu'),
                        content: Text(
                          'Czy chcesz usunąć rekord "${analysis['description']}" z historii analiz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Nie'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Tak'),
                          ),
                        ],
                      ),
                    );

                    if (confirm1 != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rekord nie został usunięty.'),
                        ),
                      );
                      return;
                    }

                    final confirm2 = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Potwierdzenie'),
                        content: const Text('Czy na pewno chcesz usunąć?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Nie'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Tak'),
                          ),
                        ],
                      ),
                    );

                    if (confirm2 != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rekord nie został usunięty.'),
                        ),
                      );
                      return;
                    }

                    final url = Uri.parse('$baseUrl/analysis/delete/');
                    final body = {'description': analysis['description'] ?? ''};

                    try {
                      final response = await http.post(
                        url,
                        headers: {
                          'Content-Type': 'application/json',
                          'Authorization': 'Token $token',
                        },
                        body: jsonEncode(body),
                      );

                      String snackMessage;
                      Color snackColor = Colors.green;

                      if (response.statusCode == 200) {
                        final respData = jsonDecode(response.body);
                        snackMessage =
                            respData['message'] ?? 'Usunięto rekord!';
                        if (onDeleteSuccess != null) {
                          onDeleteSuccess!(analysis['description']);
                        }
                      } else if (response.statusCode == 404) {
                        snackMessage = 'Nie znaleziono rekordu.';
                        snackColor = Colors.orange;
                      } else {
                        snackMessage =
                            'Błąd przy usuwaniu: ${response.statusCode}';
                        snackColor = Colors.red;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(snackMessage),
                          backgroundColor: snackColor,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Wyjątek przy wysyłaniu danych: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final audioBytes = base64Decode(analysis['audio_base64'] ?? '');
                final tempFile = File(
                  '${Directory.systemTemp.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
                );
                tempFile.writeAsBytesSync(audioBytes);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AudioAnalyzer(
                      audioPath: tempFile.path,
                      resultJson: {
                        "result": {
                          "label": analysis['result_text'],
                          "instances_preprocessed": analysis['instances'],
                          "scores": analysis['scores'],
                          "description": analysis['description'],
                        },
                      },
                    ),
                  ),
                );
              },
              child: const Text(
                "Zobacz szczegóły",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
