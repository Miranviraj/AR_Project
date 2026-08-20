import 'package:ar/screens/true_Ar.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart'; // 🌟 Added for Haptic Feedback (Vibration)
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../const/api_config.dart';
import 'chat_guide.dart';
import '../widgets/glass_container.dart';

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

  // Dynamic 3D model URL fetched directly from backend
  String _currentModelUrl = "";

  static final String _backendUrl = '${ApiConfig().baseUrl}/api/detect-ruins';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false, // 🌟 Audio false to save memory during scanning
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _scanEnvironment() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // 🌟 Haptic Feedback when scan starts
    HapticFeedback.lightImpact();

    setState(() {
      _isScanning = true;
      _recognizedLabel = "Analyzing structure...";
    });

    try {
      final XFile imageFile = await _controller!.takePicture();

      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List detections = data['detections'];

        if (detections.isNotEmpty) {
          var bestMatch = detections[0];
          String label = bestMatch['artifact_name'] ?? 'Unknown Ruin';

          String modelUrl = bestMatch['model_url'] ?? '${ApiConfig().baseUrl}/static/models/medirigiriya.glb';

          // 🌟 Haptic Feedback on Success! (Makes the app feel premium)
          HapticFeedback.heavyImpact();

          setState(() {
            _isRecognized = true;
            _recognizedLabel = label;
            _polygonCoordinates = bestMatch['polygon'] ?? [];
            _currentModelUrl = modelUrl;
          });

          _saveToUnlockedSites(label);
        } else {
          HapticFeedback.vibrate(); // Vibrate on failure
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
          behavior: SnackBarBehavior.floating, // Floating snackbar looks more modern
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
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
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

          // 2. Polygon Painter for the Ruin
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

                // Bottom Buttons
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
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

                            // Release camera hardware smoothly
                            if (_controller != null) {
                              await _controller!.dispose();
                              _controller = null;
                            }

                            if (!context.mounted) return;

                            await Navigator.push(
                              context,
                              PageRouteBuilder( // 🌟 Smooth fade transition to AR Screen
                                pageBuilder: (context, animation, secondaryAnimation) => TrueARScreen(
                                  detectedRuin: _recognizedLabel,
                                  modelUrl: _currentModelUrl,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );

                            // Restart the camera when returning
                            if (mounted) {
                              _initializeCamera();
                            }
                          },
                        ),

                      if (_isRecognized)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
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
                          padding: const EdgeInsets.only(top: 12.0),
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

// AR POLYGON PAINTER
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
      ..strokeWidth = 4.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

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