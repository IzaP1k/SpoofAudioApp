import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

const kPrimaryColor = Color.fromARGB(255, 27, 48, 105);
const kPrimaryLightColor = Color.fromARGB(255, 160, 179, 231);
const kConfirmationColor = Color.fromARGB(255, 2, 100, 32);
const kRejectionColor = Color.fromARGB(255, 153, 11, 11);

const double defaultPadding = 16.0;

final String baseUrl = kIsWeb
    ? "/api"
    : Platform.isAndroid
    ? "http://10.0.2.2:8000"
    : "http://127.0.0.1:8000";
