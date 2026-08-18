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
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _scanEnvironment() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

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
          String label = bestMatch['artifact_name'];

          setState(() {
            _isRecognized = true;
            _recognizedLabel = label;
          });

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
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

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

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.orange),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  _isRecognized ? Icons.check_circle : Icons.camera_alt,
                                  color: _isRecognized ? Colors.greenAccent : Colors.orange
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _recognizedLabel,
                                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      if (!_isRecognized)
                        FloatingActionButton.extended(
                          onPressed: _isScanning ? null : _scanEnvironment,
                          backgroundColor: Colors.orange,
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
                          onPressed: () async {
                            if (_controller != null) {
                              await _controller!.dispose();
                              _controller = null;
                            }

                            await Future.delayed(const Duration(milliseconds: 800));

                            if (!context.mounted) return;

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrueARScreen(detectedRuin: _recognizedLabel),
                              ),
                            );

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