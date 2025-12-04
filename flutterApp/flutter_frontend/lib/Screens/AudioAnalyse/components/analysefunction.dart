import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_frontend/Screens/AudioAnalyse/components/save_analyse.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/xai_analyse/xaiScreen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnalyseFunction extends StatefulWidget {
  const AnalyseFunction({
    super.key,
    this.resultText,
    this.audioPath,
    this.description,
    this.listInstancesPreprocessed,
    this.listScores,
  });

  final String? resultText;
  final String? audioPath;
  final String? description;

  final List<dynamic>? listInstancesPreprocessed;
  final List<dynamic>? listScores;

  @override
  State<AnalyseFunction> createState() => _AnalyseFunctionState();
}

class _AnalyseFunctionState extends State<AnalyseFunction> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() => isPlaying = false);
    });
  }

  Future<void> _togglePlay() async {
    if (widget.audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brak pliku audio do odtworzenia!"),
          backgroundColor: kRejectionColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (isPlaying) {
      await _audioPlayer.pause();
      setState(() => isPlaying = false);
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.audioPath!));
      setState(() => isPlaying = true);
    }
  }

  Future<void> _saveAnalysis() async {
    if (widget.resultText == null ||
        widget.description == null ||
        widget.audioPath == null ||
        widget.listInstancesPreprocessed == null ||
        widget.listScores == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brakuje danych do zapisania analizy!"),
          backgroundColor: kRejectionColor,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      bool deleteOldest = false;

      while (true) {
        final response = await AnalysisService.saveAnalysis(
          resultText: widget.resultText!,
          description: widget.description!,
          audioPath: widget.audioPath!,
          instances: widget.listInstancesPreprocessed!,
          scores: widget.listScores!,
          deleteOldest: deleteOldest,
        );

        if (response.statusCode == 200) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Analiza zapisana pomyślnie!"),
              backgroundColor: Colors.green,
            ),
          );

          break;
        } else {
          final data = jsonDecode(response.body);
          if (data['error'] == 'limit_reached') {
            final firstConfirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: kPrimaryLightColor,
                title: const Text(
                  "Limit analiz osiągnięty",
                  style: TextStyle(color: kPrimaryColor),
                ),
                content: const Text(
                  "Masz już 4 zapisane analizy. Czy chcesz usunąć najstarszą?",
                  style: TextStyle(color: Colors.black87),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      "Nie",
                      style: TextStyle(color: kPrimaryColor),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Tak",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (firstConfirm == true) {
              final secondConfirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: kPrimaryLightColor,
                  title: const Text(
                    "Potwierdzenie",
                    style: TextStyle(color: kPrimaryColor),
                  ),
                  content: const Text(
                    "Czy na pewno chcesz usunąć najstarszą analizę?",
                    style: TextStyle(color: Colors.black87),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        "Nie",
                        style: TextStyle(color: kPrimaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Tak",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (secondConfirm == true) {
                deleteOldest = true;
                continue;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Nie zapisano analizy – przekroczono limit."),
                    backgroundColor: kRejectionColor,
                  ),
                );
                break;
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Nie zapisano analizy – przekroczono limit."),
                  backgroundColor: kRejectionColor,
                ),
              );
              break;
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Błąd zapisu: ${data['error']}"),
                backgroundColor: kRejectionColor,
              ),
            );
            break;
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd połączenia: $e"),
          backgroundColor: kRejectionColor,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _analyseAndNavigate() async {
    if (widget.listInstancesPreprocessed == null || widget.listScores == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brak danych do analizy!"),
          backgroundColor: kRejectionColor,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri.parse("$baseUrl/xai/analyse_xai/");
      final String selectedModel =
          prefs.getString('selected_model') ?? 'Res_Net';
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "listInstances_preprocessed": widget.listInstancesPreprocessed,
          "listScores": widget.listScores,
          "model": selectedModel,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          jsonDecode(response.body),
        );

        final List<String> images =
            (data["images"] as List?)?.cast<String>() ?? [];
        final List<String> info = (data["info"] as List?)?.cast<String>() ?? [];

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => XaiScreen(
              audioPath: widget.audioPath,
              images: images,
              info: info,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Błąd: ${response.statusCode}"),
            backgroundColor: kRejectionColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd połączenia: $e"),
          backgroundColor: kRejectionColor,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Odsłuchaj nagrania:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _togglePlay,
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            label: Text(isPlaying ? "Pauzuj" : "Odtwórz nagranie"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            ),
          ),

          const SizedBox(height: defaultPadding),
          const Text(
            "Wynik analizy:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryLightColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              widget.resultText ?? "Brak wyniku",
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),

          const SizedBox(height: defaultPadding),
          const Text(
            "Cechy nagrania:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryLightColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              widget.description ?? "Brak dodatkowych informacji",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),

          const SizedBox(height: defaultPadding * 2),

          Center(
            child: isLoading
                ? const CircularProgressIndicator(color: kPrimaryColor)
                : ElevatedButton.icon(
                    onPressed: _saveAnalysis,
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text(
                      "Zapisz wyniki analizy",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                    ),
                  ),
          ),

          const SizedBox(height: defaultPadding),

          Center(
            child: isLoading
                ? const CircularProgressIndicator(color: kPrimaryColor)
                : ElevatedButton.icon(
                    onPressed: _analyseAndNavigate,
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text(
                      "Dowiedz się więcej",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 4,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
