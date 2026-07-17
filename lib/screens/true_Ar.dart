import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:flutter/material.dart';

import 'package:vector_math/vector_math_64.dart' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

import '../const/api_config.dart';

class TrueARScreen extends StatefulWidget {
  const TrueARScreen({super.key});

  @override
  State<TrueARScreen> createState() => _TrueARScreenState();
}

class _TrueARScreenState extends State<TrueARScreen> {
  // ⚠️ USE YOUR ACTUAL BACKEND IP
  final String _backendUrl = '${ApiConfig().baseUrl}/api/detect-ruins';


  final Map<String, String> _ruinModels = {
    'Medirigiriya Vatadage': 'assets/models/royal palace.glb',
    'Polonnaruwa Vatadage': 'assets/models/royal palace.glb',
    'Royal palace of King Parakramabahu': 'assets/models/royal palace.glb',

    // Add all your YOLO class names here...
  };
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  bool _isAnalyzing = false;

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true, // Shows dots on the ground/walls so you know AR is tracking
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
    );
    this.arObjectManager!.onInitialize();
  }

  Future<void> _scanRuinWithAI() async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    try {
      // 1. Capture a snapshot of the current AR view
      final imageProvider = await arSessionManager!.snapshot();
      Uint8List imageBytes = await _getImageBytes(imageProvider);

      // 2. Send to Python YOLO Backend
      var request = http.MultipartRequest('POST', Uri.parse(_backendUrl));
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'ar_snapshot.jpg'));
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var data = jsonDecode(responseBody);

      if (data['detections'].isNotEmpty) {
        var detection = data['detections'][0];

        // 🌟 2. Extract the class name from the AI detection
        String aiDetectedName = (detection['artifact_name'] as String).toLowerCase();

        // 🌟 3. Look up the assigned model URI from the map.
        // The "??" operator provides a default fallback if the name isn't found.
        String assignedModelUri = _ruinModels[aiDetectedName] ?? 'assets/models/default_info.glb';

        math.Matrix4? cameraPose = await arSessionManager!.getCameraPose();

        if (cameraPose != null) {
          math.Vector3 localPosition = math.Vector3(0.0, -0.2, -2.0);
          math.Vector3 worldPosition = cameraPose.transform3(localPosition);

          var customNode = ARNode(
            type: NodeType.localGLTF2,
            uri: assignedModelUri, // 🌟 4. Pass the dynamic URI right here
            scale: math.Vector3(0.2, 0.2, 0.2),
            position: worldPosition,
            rotation: math.Vector4(1.0, 0.0, 0.0, 0.0),
          );

          await arObjectManager!.addNode(customNode);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Anchored data for ${detection['artifact_name']}!")));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not determine camera position.")));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No ruins found in this frame.")));
        }
      }
    } catch (e) {
      print("AR Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  // Placeholder for Image Provider to Bytes conversion
  Future<Uint8List> _getImageBytes(ImageProvider provider) async {
    // You will implement conversion logic here based on your snapshot format
    return Uint8List(0);
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The Native AR Camera Engine
          ARView(
            onARViewCreated: onARViewCreated,
          ),

          // UI Overlay
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: _isAnalyzing ? null : _scanRuinWithAI,
                icon: _isAnalyzing
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Icon(Icons.radar, color: Colors.black),
                label: Text(
                  _isAnalyzing ? "Scanning Geometry..." : "Scan & Anchor",
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}