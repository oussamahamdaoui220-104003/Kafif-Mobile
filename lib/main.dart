import 'dart:io';
import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'about_page.dart';
import 'result_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlindAssistApp());
}

class BlindAssistApp extends StatelessWidget {
  const BlindAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5), // indigo/purple like the shot
        brightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'BlindAssist - Moroccan Currency',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F4F5), // soft grey background
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF111827),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      cardTheme: CardThemeData(
  color: Colors.white,
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  ),
),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textTheme: base.textTheme.apply(
          bodyColor: const Color(0xFF111827),
          displayColor: const Color(0xFF111827),
        ),
      ),
      home: const CurrencyScannerPage(),
    );
  }
}


class CurrencyScannerPage extends StatefulWidget {
  const CurrencyScannerPage({super.key});

  @override
  State<CurrencyScannerPage> createState() => _CurrencyScannerPageState();
}

class _CurrencyScannerPageState extends State<CurrencyScannerPage> {
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _tts = FlutterTts();
  Interpreter? _interpreter;

  bool _isLoadingModel = true;
  bool _isProcessing = false;
  File? _lastImage;
  String? _lastResult;
  bool _useFrontCamera = false;   // false = back camera, true = front
  int _homeTapCount = 0;       // 👈 how many taps
  Timer? _homeTapTimer;        // 👈 timer to distinguish double vs triple tap

  // ORDER MUST MATCH THE TRAINING CLASSES
  final List<String> _labels = [
    '1',
    '10',
    '100',
    '20',
    '200',
    '5',
    '50',
  ];

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// Initialize TTS + model, then speak instructions in order
Future<void> _initApp() async {
  await _setupTts();
  await _loadModel();
  await _announceInstructions();   // speak instructions first
}



  Future<void> _setupTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true); // wait until each speak finishes
  }

Future<void> _announceInstructions() async {
  await _speak(
    "The recognition model is ready. "
    "Please hold the currency in front of the camera in a clear position. "
    "You can double tap anywhere on the screen to hear these instructions again, "
    "and triple tap to open the camera.",
  );
}


  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/currency.tflite');
      debugPrint("✅ Model loaded");

      setState(() {
        _isLoadingModel = false;
      });

      // We DON'T speak here anymore to avoid overlapping messages.
    } catch (e) {
      debugPrint("❌ Error loading model: $e");
      setState(() {
        _isLoadingModel = false;
      });
      await _speak("Error loading the recognition model.");
    }
  }

 @override
void dispose() {
  _interpreter?.close();
  _tts.stop();
  _homeTapTimer?.cancel();   // 👈 stop timer if still running
  super.dispose();
}

Future<void> _pickFromCamera() async {
  if (_isProcessing || _isLoadingModel) return;

  // 🔴 STOP ANY CURRENT SPEECH BEFORE OPENING CAMERA
  await _tts.stop();

  setState(() => _isProcessing = true);

  try {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final file = File(photo.path);
    await _processImage(file);
  } catch (e) {
    debugPrint("Error picking from camera: $e");
    await _speak("Error while scanning from camera.");
    setState(() => _isProcessing = false);
  }
}



Future<void> _processImage(File file) async {
  if (_interpreter == null) {
    await _speak("Model not ready. Please try again.");
    setState(() => _isProcessing = false);
    return;
  }

  final label = await _runInference(file);
  final spoken = _labelToSpeechText(label);

  setState(() {
    _lastImage = file;
    _lastResult = spoken;
    _isProcessing = false;
  });

  if (!mounted) return;

  // 👇 Wait for ResultPage to finish and return a value
  final bool? shouldRescan = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => ResultPage(
        resultText: spoken,
        imageFile: file,
      ),
    ),
  );

  // If ResultPage says "rescan", open camera again automatically
  if (shouldRescan == true) {
    await Future.delayed(const Duration(milliseconds: 300));
    _pickFromCamera();
  }
}


  Future<String> _runInference(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? raw = img.decodeImage(bytes);

    if (raw == null) {
      debugPrint("Could not decode image");
      return "unknown";
    }

    // 1) Resize first (smaller, faster)
    final img.Image resizedBase = img.copyResize(
      raw,
      width: 400,
    );

    // 2) Aggressive center crop (about 60% of the image)
    final int minSide =
        resizedBase.width < resizedBase.height ? resizedBase.width : resizedBase.height;
    final int cropSize = (minSide * 0.60).toInt();
    final int offsetX = (resizedBase.width - cropSize) ~/ 2;
    final int offsetY = (resizedBase.height - cropSize) ~/ 2;

    final img.Image cropped = img.copyCrop(
      resizedBase,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );

    // 3) Resize to 224x224 for the model
    final img.Image resized = img.copyResize(
      cropped,
      width: 224,
      height: 224,
    );

    // 4) Prepare input [1, 224, 224, 3] with RAW pixels 0–255
    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final p = resized.getPixel(x, y);
            final double r = p.r.toDouble();
            final double g = p.g.toDouble();
            final double b = p.b.toDouble();
            return [r, g, b];
          },
        ),
      ),
    );

    // 5) Output buffer [1, numClasses]
    final output = List.generate(
      1,
      (_) => List<double>.filled(_labels.length, 0.0),
    );

    _interpreter!.run(input, output);
    final probs = output[0];

    // Argmax
    int bestIdx = 0;
    double bestProb = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > bestProb) {
        bestProb = probs[i];
        bestIdx = i;
      }
    }

    final label = _labels[bestIdx];
    debugPrint("Predicted: $label (prob=${bestProb.toStringAsFixed(4)})");

    const double threshold = 0.40;
    if (bestProb < threshold) {
      debugPrint("Low confidence -> unknown");
      return "unknown";
    }

    return label;
  }

  String _labelToSpeechText(String label) {
    switch (label) {
      case '1':
        return "One dirham";
      case '5':
        return "Five dirhams";
      case '10':
        return "Ten dirhams";
      case '20':
        return "Twenty dirhams";
      case '50':
        return "Fifty dirhams";
      case '100':
        return "One hundred dirhams";
      case '200':
        return "Two hundred dirhams";
      case 'unknown':
        return "I am not sure about this currency, please try again.";
      default:
        return "I am not sure about this currency, please try again.";
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("TTS error: $e");
    }
  }
void _handleHomeTap() {
  _homeTapCount++;

  _homeTapTimer?.cancel();
  _homeTapTimer = Timer(const Duration(milliseconds: 350), () {
    // 🔴 STOP ANY CURRENT SPEECH FIRST
    _tts.stop();

    if (_homeTapCount == 2) {
      // 🔹 DOUBLE TAP → repeat instructions
      _announceInstructions();
    } else if (_homeTapCount == 3) {
      // 🔹 TRIPLE TAP → open camera again
      _pickFromCamera();
    }

    _homeTapCount = 0;
  });
}


  @override
 @override
Widget build(BuildContext context) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _handleHomeTap,   // 👈 this handles double + triple tap
    child: Scaffold(

      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo/app_logo.png',
              height: 28,
            ),
            const SizedBox(width: 10),
            const Text('BlindAssist'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AboutPage()),
              );
            },
            child: const Text('About'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // 🔹 Top card: app summary (like the big card in your reference UI)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFE5E7EB),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.visibility,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BlindAssist',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Moroccan currency recognition for blind users.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 Instruction card – instead of plain text in the middle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'How to scan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Please hold the currency in front of the camera in a clear position and click the button to start scanning. "
                        "I will detect the value and speak it automatically.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      SizedBox(height: 8),
                   Text(
  'Tip: Double tap anywhere on this screen to hear these instructions again.\n'
  'Triple tap anywhere to open the camera.',
  style: TextStyle(
    fontSize: 13,
    height: 1.5,
    color: Color(0xFF9CA3AF),
  ),
),

                    ],
                  ),
                ),
              ),

              const Spacer(),

              // 🔹 Bottom floating control bar (like the bottom bar in your screenshot)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomPillButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onPressed: _isLoadingModel ? null : _pickFromCamera,
                      isPrimary: true,
                    ),
                 
                  ],
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
class _BottomPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _BottomPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isPrimary ? scheme.primary : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary ? Colors.white : const Color(0xFF111827),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
