import 'package:flutter/material.dart';
import 'package:flutter_frontend/Screens/AudioAnalyse/components/analyse_image.dart';
import 'package:flutter_frontend/Screens/AudioAnalyse/components/analysefunction.dart';
import 'package:flutter_frontend/Screens/Mainpage/components/appbar.dart';
import 'package:flutter_frontend/components/background.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:flutter_frontend/Screens/Settings/settings_screen.dart';

class AudioAnalyzer extends StatefulWidget {
  final Map<String, dynamic>? resultJson;
  final String? audioPath;

  const AudioAnalyzer({super.key, this.resultJson, this.audioPath});

  @override
  State<AudioAnalyzer> createState() => _AudioAnalyzerState();
}

class _AudioAnalyzerState extends State<AudioAnalyzer> {
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
              Navigator.pop(context);
            },
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Responsive(
          mobile: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: defaultPadding * 2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Analiza na żywo",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const AnalyseImage(),
              const SizedBox(height: defaultPadding * 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: AnalyseFunction(
                  resultText: widget.resultJson?["result"]?["label"],
                  audioPath: widget.audioPath,
                  description: widget.resultJson?["result"]?["description"],
                ),
              ),
            ],
          ),
          desktop: Row(
            children: [
              const Expanded(flex: 5, child: AnalyseImage()),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: defaultPadding,
                    right: defaultPadding * 4,
                    top: defaultPadding,
                    bottom: defaultPadding * 2,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: defaultPadding * 2),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Analiza na żywo",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: defaultPadding),
                      AnalyseFunction(
                        resultText: widget.resultJson?["result"]?["label"],
                        audioPath: widget.audioPath,
                        description:
                            widget.resultJson?["result"]?["description"],
                      ),
                      const SizedBox(height: defaultPadding * 2),
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
