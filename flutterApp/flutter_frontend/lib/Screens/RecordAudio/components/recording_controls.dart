import 'package:flutter/material.dart';
import '../../../constants.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onSave,
    required this.isRecording,
  });

  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback onSave;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Nagrywanie głosu",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: isRecording ? onPause : onStart,
          icon: Icon(isRecording ? Icons.pause : Icons.mic),
          label: Text(isRecording ? "Pauza" : "Rozpocznij nagrywanie"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop),
          label: const Text("Zakończ nagrywanie"),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryLightColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.upload),
          label: const Text("Wyślij nagranie na serwer"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
