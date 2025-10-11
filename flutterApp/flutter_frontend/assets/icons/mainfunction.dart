import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../../constants.dart';
import '../../AudioAnalyse/audioanalyse.dart';

class MainFunction extends StatefulWidget {
  const MainFunction({super.key});

  @override
  State<MainFunction> createState() => _MainFunctionState();
}

class _MainFunctionState extends State<MainFunction> {
  File? pickedFile;

  Future<void> pickFile() async {
    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Możesz dodać tylko 1 plik!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['flac', 'wav', 'mp3', 'mp4'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        pickedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadFile() async {
    if (pickedFile == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://127.0.0.1:8000/upload/file/"),
    );

    request.files.add(
      await http.MultipartFile.fromPath("file", pickedFile!.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Plik wysłany pomyślnie!")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AudioAnalyzer()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Błąd: ${response.statusCode}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // 🔹 wyrównuje do lewej
      child: SizedBox(
        width: double.infinity, // 🔹 pozwala rozciągać się maksymalnie
        child: _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Wybierz plik
          SizedBox(
            width: double.infinity, // 🔹 pełna szerokość
            child: ElevatedButton(
              onPressed: pickFile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Wybierz plik",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding),

          // 🔹 Analiza na żywo
          SizedBox(
            width: double.infinity, // 🔹 pełna szerokość
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AudioAnalyzer(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Analiza na żywo",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: defaultPadding * 2),

          // 🔹 Wybrany plik + usuń + zatwierdź
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
                  width: double.infinity, // 🔹 pełna szerokość
                  child: ElevatedButton(
                    onPressed: uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
