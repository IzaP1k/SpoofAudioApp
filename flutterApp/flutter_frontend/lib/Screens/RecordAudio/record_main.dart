import 'package:flutter/material.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/appbar.dart';
import 'package:flutter_frontend/Screens/Mainpage/main_page.dart';
import 'package:flutter_frontend/Screens/RecordAudio/components/record_image.dart';
import 'package:flutter_frontend/Screens/RecordAudio/components/audiofunction.dart';
import 'package:flutter_frontend/Screens/Settings/settings_screen.dart';
import 'package:flutter_frontend/Screens/AudioAnalyse/audioanalyse.dart';
import 'package:flutter_frontend/components/background.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_frontend/constants.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnlineRecorder extends StatefulWidget {
  const OnlineRecorder({super.key});

  @override
  State<OnlineRecorder> createState() => _OnlineRecorderState();
}

class _OnlineRecorderState extends State<OnlineRecorder> {
  final AudioRecorder audioRecorder = AudioRecorder();
  String? recordingPath;
  bool isRecording = false;

  Future<void> _toggleRecording() async {
    if (isRecording) {
      String? filepath = await audioRecorder.stop();
      if (filepath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nagranie zapisane!"),
            backgroundColor: kConfirmationColor,
          ),
        );
        setState(() {
          isRecording = false;
          recordingPath = filepath;
        });
      }
    } else {
      if (await audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/recorded_audio.m4a';
        await audioRecorder.start(const RecordConfig(), path: filePath);
        setState(() {
          isRecording = true;
          recordingPath = null;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Brak uprawnień do nagrywania"),
            backgroundColor: kRejectionColor,
          ),
        );
      }
    }
  }

  Future<void> uploadFile() async {
    if (recordingPath == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: kPrimaryColor,
            size: 90,
          ),
        );
      },
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
      print("Wysyłanie pliku z modelem: $selectedModel");

      request.files.add(
        await http.MultipartFile.fromPath("file", recordingPath!),
      );

      var response = await request.send();

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(respStr);
        print("JSON poprawny: $jsonResponse");

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AudioAnalyzer(
                resultJson: jsonResponse,
                audioPath: recordingPath!,
              ),
            ),
          );
        }
      } else {
        print("Błąd: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Błąd: ${response.statusCode}"),
            backgroundColor: kRejectionColor,
          ),
        );
      }
    } catch (e) {
      // ZAMYKANIE ANIMACJI w przypadku błędu
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Błąd przesyłania: $e"),
          backgroundColor: kRejectionColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Responsive(
          mobile: _buildMobileLayout(context),
          desktop: _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const RecordImage(),
        const SizedBox(height: defaultPadding * 2),
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: defaultPadding),
            child: Text(
              "Nagraj dźwięk",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                fontSize: 24,
              ),
            ),
          ),
        ),
        const SizedBox(height: defaultPadding * 2),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 8,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleRecording,
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    label: Text(
                      isRecording
                          ? "Zatrzymaj nagrywanie"
                          : "Rozpocznij nagrywanie",
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
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (recordingPath != null) ...[
                    AudioFunction(audioPath: recordingPath!),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: uploadFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kConfirmationColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          "Zatwierdź",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 4, child: RecordImage()),
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(
              left: defaultPadding,
              right: defaultPadding * 4,
              top: defaultPadding * 2,
              bottom: defaultPadding * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: Text(
                      "Nagraj dźwięk",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: defaultPadding * 2),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(isRecording ? Icons.stop : Icons.mic),
                        label: Text(
                          isRecording
                              ? "Zatrzymaj nagrywanie"
                              : "Rozpocznij nagrywanie",
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
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (recordingPath != null) ...[
                        AudioFunction(audioPath: recordingPath!),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: uploadFile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kConfirmationColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Zatwierdź",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
