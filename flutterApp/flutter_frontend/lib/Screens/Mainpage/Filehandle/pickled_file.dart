import 'dart:io';
import 'package:flutter_frontend/constants.dart';
import 'package:http/http.dart' as http;

Future<void> uploadFile(File file, String modelName) async {
  var uri = Uri.parse("$baseUrl/api/upload/");
  var request = http.MultipartRequest('POST', uri);


  request.files.add(await http.MultipartFile.fromPath('file', file.path));


  request.fields['model'] = modelName;

  var response = await request.send();

  if (response.statusCode == 200) {
    print("Plik wysłany poprawnie z modelem: $modelName");
  } else {
    print("Błąd: ${response.statusCode}");
  }
}
