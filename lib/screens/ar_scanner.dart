import 'package:ar/screens/true_Ar.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../const/api_config.dart';
import 'chat_guide.dart';

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
  List<dynamic> _polygonCoordinates = []; // Stores your YOLO segmentation points!

  // Presentation State
  bool _show3DModel = false;

  // ⚠️ CHANGE THIS TO YOUR LAPTOP'S IPV4 ADDRESS!
  static final String _backendUrl = '${ApiConfig().baseUrl}/api/detect-ruins';

  // Dynamic 3D Model Mapping
  final Map<String, String> _modelLinks = {
    "Abhayagiri": "https://modelviewer.dev/shared-assets/models/Astronaut.glb",
    "Moonstone": "https://modelviewer.dev/shared-assets/models/shishkebab.glb",
    "Lion Pillar": "https://modelviewer.dev/shared-assets/models/RobotExpressive.glb"
  };

  String get _currentModelUrl {
    return _modelLinks[_recognizedLabel] ?? "https://modelviewer.dev/shared-assets/models/Astronaut.glb";
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.high ,      enableAudio: true, // <-- Audio is now enabled
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  // 🌟 THE NEW BACKEND CONNECTION
  Future<void> _scanEnvironment() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isScanning = true;
      _recognizedLabel = "Analyzing structure...";
    });

    try {
      // 1. Take a high-resolution photo
      final XFile imageFile = await _controller!.takePicture();

      // 2. Send it to your FastAPI Server
      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List detections = data['detections'];

        if (detections.isNotEmpty) {
          // Grab the first object YOLO found
          var bestMatch = detections[0];
          String label = bestMatch['artifact_name'];

          setState(() {
            _isRecognized = true;
            _recognizedLabel = label;
            _polygonCoordinates = bestMatch['polygon']; // We save the AR points!
          });

          // Print the exact pixel coordinates to your terminal for AR mapping later!
          print("Polygons mapped for $label: $_polygonCoordinates");

          _saveToUnlockedSites(label);
        } else {
          setState(() {
            _recognizedLabel = "No ruins detected. Try another angle.";
          });
        }
      } else {
        setState(() => _recognizedLabel = "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Network error: $e");
      setState(() => _recognizedLabel = "Could not connect to AI server.");
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _saveToUnlockedSites(String label) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Artifact Identified: $label!'), backgroundColor: Colors.green),
      );
      final prefs = await SharedPreferences.getInstance();
      List<String> saved = prefs.getStringList('unlocked_sites') ?? [];
      if (!saved.contains(label)) prefs.setStringList('unlocked_sites', [...saved, label]);
    }
  }

  void _resetScanner() {
    setState(() {
      _isRecognized = false;
      _show3DModel = false;
      _recognizedLabel = "Point at a ruin and tap Scan";
      _polygonCoordinates = [];
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
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

          if (_isRecognized && _polygonCoordinates.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: RuinPolygonPainter(_polygonCoordinates),
              ),
            ),
          // 2. The Dynamic 3D Model Overlay
          if (_show3DModel)
            Positioned.fill(
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 4.0,
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: ModelViewer(
                      src: _currentModelUrl,
                      alt: "3D Reconstruction of $_recognizedLabel",
                      ar: false,
                      autoRotate: true,
                      cameraControls: true,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),

          // 3. UI Overlay
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          _isRecognized ? Icons.check_circle : Icons.camera_alt,
                          color: _isRecognized ? Colors.greenAccent : const Color(0xFFD4AF37)
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _recognizedLabel,
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // The New Scan Button!
                      if (!_isRecognized)
                        FloatingActionButton.extended(
                          onPressed: _isScanning ? null : _scanEnvironment,
                          backgroundColor: const Color(0xFFD4AF37),
                          icon: _isScanning
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.document_scanner, color: Colors.black),
                          label: Text(
                              _isScanning ? "Analyzing..." : "SCAN RUIN",
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
                          ),
                        ),

                      if (_isRecognized)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          icon: const Icon(Icons.view_in_ar, color: Colors.black),
                          label: const Text("Launch True AR", style: TextStyle(color: Colors.black, fontSize: 18)),
                          onPressed: () {
                            // Turn off the camera on this screen to free up resources
                            _controller?.pausePreview();

                            // Navigate to your AR plugin screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrueARScreen(detectedRuin: _recognizedLabel),
                              ),
                            ).then((_) {
                              // Restart the camera preview when coming back from AR
                              _controller?.resumePreview();
                            });
                          },
                        ),

                      if (_isRecognized)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            icon: const Icon(Icons.chat, color: Colors.black),
                            label: const Text("Open AI Tourist Guide", style: TextStyle(color: Colors.black, fontSize: 18)),
                            onPressed: () {
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
                          padding: const EdgeInsets.only(top: 16.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.refresh, color: Colors.white70),
                            label: const Text("Scan Another Ruin", style: TextStyle(color: Colors.white70)),
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

// 🌟 THE AR POLYGON PAINTER
class RuinPolygonPainter extends CustomPainter {
  final List<dynamic> polygonPoints;

  RuinPolygonPainter(this.polygonPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (polygonPoints.isEmpty) return;

    // Glowing Gold Fill
    final paintFill = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Solid Gold Border line
    final paintStroke = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < polygonPoints.length; i++) {
      // Multiply the percentage by the actual screen width/height
      double x = polygonPoints[i][0] * size.width;
      double y = polygonPoints[i][1] * size.height;

      if (i == 0) {
        path.moveTo(x, y); // Start the pen here
      } else {
        path.lineTo(x, y); // Draw a line to the next dot
      }
    }
    path.close(); // Connect the last dot back to the first dot

    // Draw it on the screen!
    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}