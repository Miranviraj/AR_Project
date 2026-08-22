import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../const/api_config.dart';
import 'chat_guide.dart';
import 'true_Ar.dart';
import '../widgets/glass_container.dart';
import '../widgets/info_card.dart';

class ScannerCheatScreen extends StatefulWidget {
  final CameraDescription camera;
  const ScannerCheatScreen({super.key, required this.camera});

  @override
  State<ScannerCheatScreen> createState() => _ScannerCheatScreenState();
}

class _ScannerCheatScreenState extends State<ScannerCheatScreen> {
  CameraController? _controller;

  // AI State Variables
  bool _isScanning = false;
  bool _isRecognized = false;
  String _recognizedLabel = "Point at a ruin and tap Scan";
  List<dynamic> _polygonCoordinates = [];
  String _currentModelUrl = "";

  static final String _backendUrl = '${ApiConfig().baseUrl}/api/detect-ruins';

  // Info Card & Audio Variables
  String _ruinDescription = "Retrieving information about this historical site...";
  bool _isPlayingAudio = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initTTS();
  }

  void _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    // iOS Silent Mode Bypass
    await flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    });
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _scanEnvironment() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isScanning = true;
      _recognizedLabel = "Analyzing structure...";
      _ruinDescription = "Retrieving information about this historical site...";
    });

    try {
      final XFile imageFile = await _controller!.takePicture();

      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));

      // 🌟 පරණ කෝඩ් එක වෙනුවට මේ අලුත් කෝඩ් එක දාන්න 🌟
      // (මේකෙන් ෆොටෝ එකේ Path එක වෙනුවට Bytes ටික කෙළින්ම ගන්නවා, එතකොට Web එකෙත් වැඩ!)
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List detections = data['detections'];

        if (detections.isNotEmpty) {
          var bestMatch = detections[0];
          String label = bestMatch['artifact_name'] ?? 'Unknown Ruin';

          String modelUrl = bestMatch['model_url'] ?? '${ApiConfig().baseUrl}/static/models/medirigiriya.glb';

          HapticFeedback.heavyImpact();

          setState(() {
            _isRecognized = true;
            _recognizedLabel = label;
            _polygonCoordinates = bestMatch['polygon'] ?? [];
            _currentModelUrl = modelUrl;
          });

          _fetchHistoricalInfo(label);
          _saveToUnlockedSites(label);
        } else {
          HapticFeedback.vibrate();
          setState(() {
            _recognizedLabel = "No ruins detected. Try another angle.";
          });
        }
      } else {
        setState(() => _recognizedLabel = "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Network error: $e");
      setState(() => _recognizedLabel = "Could not connect to AI server.");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _saveToUnlockedSites(String label) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Artifact Identified: $label!', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      List<String> saved = prefs.getStringList('unlocked_sites') ?? [];
      if (!saved.contains(label)) prefs.setStringList('unlocked_sites', [...saved, label]);
    }
  }

  void _resetScanner() {
    HapticFeedback.selectionClick();
    setState(() {
      _isRecognized = false;
      _recognizedLabel = "Point at a ruin and tap Scan";
      _polygonCoordinates = [];
      _currentModelUrl = "";
      _isPlayingAudio = false;
    });
    flutterTts.stop();
  }

  Future<void> _fetchHistoricalInfo(String artifactName) async {
    final String apiUrl = '${ApiConfig().baseUrl}/api/chat';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "message": "Tell me about this place in 3 short sentences.",
          "artifact_name": artifactName,
          "target_lang_code": "en"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _ruinDescription = data['reply'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching info: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Background
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Glowing Polygon Overlay
          if (_isRecognized && _polygonCoordinates.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: RuinPolygonPainter(_polygonCoordinates),
              ),
            ),

          // 3. UI Overlay
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Status Bar
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25)),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          _isRecognized ? Icons.check_circle : Icons.document_scanner_rounded,
                          color: _isRecognized ? Colors.greenAccent : Colors.orange
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _recognizedLabel,
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Controls & Info Card
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info Card
                      if (_isRecognized && _recognizedLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InfoCard(
                            title: _recognizedLabel,
                            description: _ruinDescription,
                            isPlaying: _isPlayingAudio,
                            onPlayAudio: () async {
                              if (_isPlayingAudio) {
                                await flutterTts.stop();
                                setState(() {
                                  _isPlayingAudio = false;
                                });
                              } else {
                                setState(() {
                                  _isPlayingAudio = true;
                                });
                                await flutterTts.speak(_ruinDescription);
                              }
                            },
                          ),
                        ),

                      if (!_isRecognized)
                        FloatingActionButton.extended(
                          onPressed: _isScanning ? null : _scanEnvironment,
                          backgroundColor: Colors.orange,
                          elevation: 8,
                          icon: _isScanning
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.document_scanner, color: Colors.black),
                          label: Text(
                              _isScanning ? "Analyzing..." : "SCAN RUIN",
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),

                      if (_isRecognized)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.black,
                            elevation: 10,
                            shadowColor: Colors.orangeAccent.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          icon: const Icon(Icons.view_in_ar_rounded, size: 28),
                          label: const Text("Launch True AR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            HapticFeedback.lightImpact();

                            if (_controller != null) {
                              await _controller!.dispose();
                              _controller = null;
                            }

                            if (!context.mounted) return;

                            await Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => TrueARScreen(
                                  detectedRuin: _recognizedLabel,
                                  modelUrl: _currentModelUrl,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );

                            if (mounted) {
                              _initializeCamera();
                            }
                          },
                        ),

                      if (_isRecognized)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            icon: const Icon(Icons.chat_bubble_rounded),
                            label: const Text("Open AI Tourist Guide", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatGuideScreen(recognizedArtifact: _recognizedLabel),
                                ),
                              );
                            },
                          ),
                        ),

                      if (_isRecognized)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                            label: const Text("Scan Another Ruin", style: TextStyle(color: Colors.white70, fontSize: 16)),
                            onPressed: _resetScanner,
                          ),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RuinPolygonPainter extends CustomPainter {
  final List<dynamic> polygonPoints;

  RuinPolygonPainter(this.polygonPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (polygonPoints.isEmpty) return;

    final paintFill = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final path = Path();

    for (int i = 0; i < polygonPoints.length; i++) {
      double x = polygonPoints[i][0] * size.width;
      double y = polygonPoints[i][1] * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}