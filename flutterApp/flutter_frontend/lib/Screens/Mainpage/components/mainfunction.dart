import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_frontend/Screens/HistoryAnalyse/history_screen.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/chooseModel.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/Screens/AudioAnalyse/audioanalyse.dart';
import 'package:flutter_frontend/Screens/RecordAudio/record_main.dart';

class MainFunction extends StatefulWidget {
  const MainFunction({super.key});

  @override
  State<MainFunction> createState() => _MainFunctionState();
}

class _MainFunctionState extends State<MainFunction> {
  File? pickedFile;
  int selectedIndex = 0;

  final List<Map<String, String>> models = const [
    {
      "name": "Model 1",
      "info":
          "Model skupiony na dokładności. Najwyższa skuteczność. Brak faworyzacji klas.",
    },
    {
      "name": "Model 2",
      "info":
          "Model o wysokiej skuteczności, ale niższej niż model 1. Skupiony na czułości na wszelkie manipulacje głosowe. Faworyzuje wykrywanie manipulacji.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();
  }

  Future<void> _loadSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString('selected_model');
    if (savedModel != null) {
      final index = models.indexWhere((m) => m['name'] == savedModel);
      if (index != -1 && index != selectedIndex) {
        setState(() {
          selectedIndex = index;
        });
      }
    }
  }

  Future<void> _saveSelectedModel(String modelName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_model', modelName);
  }

  Future<void> pickFile() async {
    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Możesz dodać tylko 1 plik!"),
          backgroundColor: kRejectionColor,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['flac', 'wav', 'mp3', 'ogg', 'm4a'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        pickedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (pickedFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: kPrimaryColor,
          size: 90,
        ),
      ),
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/upload/file/"),
      );

      final prefs = await SharedPreferences.getInstance();
      final String selectedModel =
          prefs.getString('selected_model') ?? 'model_1';
      request.fields['model_name'] = selectedModel;

      request.files.add(
        await http.MultipartFile.fromPath("file", pickedFile!.path),
      );

      var response = await request.send();
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(respStr);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AudioAnalyzer(
              resultJson: jsonResponse,
              audioPath: pickedFile!.path,
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
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd przesyłania: $e"),
          backgroundColor: kRejectionColor,
        ),
      );
    }
  }

  Future<void> _fetchAnalyses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brak tokena autoryzacyjnego"),
          backgroundColor: kRejectionColor,
        ),
      );
      return;
    }

    final uri = Uri.parse("$baseUrl/analysis/get/");

    try {
      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == "ok") {
          final List analyses = data["records"] ?? [];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HistoryScreen(analysesData: analyses),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Błąd: ${data['error'] ?? 'Nieznany'}"),
              backgroundColor: kRejectionColor,
            ),
          );
        }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(width: double.infinity, child: _buildForm()),
    );
  }

  Widget _buildForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pickFile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                "Wybierz plik",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: defaultPadding),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnlineRecorder()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryLightColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                "Nagraj dźwięk",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),

          const SizedBox(height: defaultPadding * 3),
          
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Sprawdź historię analiz",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _fetchAnalyses,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryLightColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                "Zobacz analizy",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
          ),

          const SizedBox(height: defaultPadding * 3),
          
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Dobór modelu",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),
          Center(
            child: ModelSelector(
              models: models,
              initialSelectedIndex: selectedIndex,
              onSelected: (model, index) {
                setState(() {
                  selectedIndex = index;
                });
                _saveSelectedModel(model);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Wybrano $model"),
                    backgroundColor: kConfirmationColor,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: defaultPadding * 2),
          
          if (pickedFile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        color: Colors.blueGrey,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pickedFile!.path.split('/').last,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              pickedFile!.path,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            pickedFile = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kConfirmationColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Zatwierdź",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
