import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/appbar.dart';
import 'package:flutter_frontend/Screens/Mainpage/main_page.dart';
import 'package:flutter_frontend/Screens/Settings/settings_screen.dart';
import 'package:flutter_frontend/components/background.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:flutter_frontend/xai_analyse/components/xai_image.dart';
import 'package:on_popup_window_widget/on_popup_window_widget.dart';
import 'package:on_process_button_widget/on_process_button_widget.dart';

class XaiScreen extends StatefulWidget {
  final String? audioPath;
  final List<String>? images;
  final List<String>? info;

  const XaiScreen({super.key, this.audioPath, this.images, this.info});

  @override
  State<XaiScreen> createState() => _XaiScreenState();
}

class _XaiScreenState extends State<XaiScreen> {
  Future<void> _showImagePopup(Uint8List imageBytes, String? infoText) async {
    await showDialog(
      context: context,
      builder: (context) {
        return OnPopupWindowWidget(
          biggerMaxSize: 1800,
          intend: 0,
          title: const Text("Szczegóły analizy"),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              children: [
                Image.memory(imageBytes, fit: BoxFit.contain),
                const SizedBox(height: 15),
                if (infoText != null)
                  Text(
                    infoText,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.images ?? [];
    final List<String> info = widget.info ?? [];

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
          mobile: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: defaultPadding * 2),
              const Text(
                "Wyniki analizy XAI",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: defaultPadding),

              ...List.generate(images.length, (index) {
                Uint8List bytes = base64Decode(images[index]);
                final String? infoText = (index < info.length)
                    ? info[index]
                    : null;

                return Padding(
                  padding: const EdgeInsets.all(defaultPadding),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showImagePopup(bytes, infoText),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              height: 220,
                            ),
                          ),
                        ),
                        if (infoText != null) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: defaultPadding,
                            ),
                            child: Text(
                              infoText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          desktop: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(flex: 4, child: XaiImage()),
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(defaultPadding * 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Analiza nagrania",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: defaultPadding * 1.5),

                      ...List.generate(images.length, (index) {
                        Uint8List bytes = base64Decode(images[index]);
                        final String? infoText = (index < info.length)
                            ? info[index]
                            : null;

                        return Padding(
                          padding: const EdgeInsets.all(defaultPadding),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(defaultPadding),
                                  child: Column(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () =>
                                            _showImagePopup(bytes, infoText),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.memory(
                                            bytes,
                                            fit: BoxFit.contain,
                                            height: 220,
                                          ),
                                        ),
                                      ),
                                      if (infoText != null) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          infoText,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
