import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ResultPage extends StatefulWidget {
  final String resultText;
  final File? imageFile;

  const ResultPage({
    super.key,
    required this.resultText,
    this.imageFile,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final FlutterTts _tts = FlutterTts();

  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _setupTtsAndSpeak();
  }

  /// SPEAK RESULT + SPEAK GESTURE INSTRUCTIONS
  Future<void> _setupTtsAndSpeak() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    // 1) Speak the detected result (ex: "Twenty dirhams")
    await _tts.speak(widget.resultText);

    // 2) Then speak instructions for blind users
    await _tts.speak(
      "You can double tap anywhere to go back to the scanner. "
      "You can triple tap to hear this result again."
    );
  }

  /// DETECT DOUBLE-TAP & TRIPLE-TAP
/// DETECT DOUBLE-TAP & TRIPLE-TAP
/// DETECT DOUBLE-TAP & TRIPLE-TAP
void _handleTap() {
  _tapCount++;

  _tapTimer?.cancel();
  _tapTimer = Timer(const Duration(milliseconds: 350), () async {
    // 🔴 STOP ANY CURRENT SPEECH FIRST
    await _tts.stop();

    if (_tapCount == 2) {
      // 🔵 DOUBLE TAP → GO BACK AND RESCAN
      Navigator.pop(context, true);  // return true so home reopens camera
    } else if (_tapCount == 3) {
      // 🔵 TRIPLE TAP → REPEAT RESULT
      await _tts.speak(widget.resultText);
    }

    _tapCount = 0;
  });
}



  @override
  void dispose() {
    _tapTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // register taps anywhere
      onTap: _handleTap,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          title: const Text(
            'Recognition Result',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Currency image if available
                if (widget.imageFile != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        widget.imageFile!,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.monetization_on,
                      size: 120, color: Colors.deepPurple),

                // Detected text
                Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Detected currency:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.resultText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Visual gesture instructions (for low-vision users)
                    const Text(
                      'Accessibility:\n'
                      '- Double tap anywhere to go back to the scanner.\n'
                      '- Triple tap anywhere to repeat the result.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),

                // Button for sighted users
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
