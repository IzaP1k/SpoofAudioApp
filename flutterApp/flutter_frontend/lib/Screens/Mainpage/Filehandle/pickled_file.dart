import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> uploadFile(File file) async {
  var uri = Uri.parse("http://127.0.0.1:8000/api/upload/");
  var request = http.MultipartRequest('POST', uri);

  request.files.add(await http.MultipartFile.fromPath('file', file.path));

  var response = await request.send();

  if (response.statusCode == 200) {
    print("Plik wysłany poprawnie!");
  } else {
    print("Błąd: ${response.statusCode}");
  }
}
