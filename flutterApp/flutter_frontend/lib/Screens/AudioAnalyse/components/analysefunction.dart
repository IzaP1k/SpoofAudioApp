import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../constants.dart';

class AnalyseFunction extends StatefulWidget {
  const AnalyseFunction({
    super.key,
    this.resultText,
    this.audioPath,
    this.description,
  });

  final String? resultText;
  final String? audioPath;
  final String? description;

  @override
  State<AnalyseFunction> createState() => _AnalyseFunctionState();
}

class _AnalyseFunctionState extends State<AnalyseFunction> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  Future<void> _togglePlay() async {
    if (widget.audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Brak pliku audio do odtworzenia!")),
      );
      return;
    }

    if (isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.audioPath!));
      setState(() {
        isPlaying = true;
      });
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
        ],
      ),
    );
  }
}
