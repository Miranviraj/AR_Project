import 'dart:io' show Platform; // 🌟 Required to check iOS vs Android
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:ar_flutter_plugin_plus/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;
import '../widgets/glass_container.dart';

class TrueARScreen extends StatefulWidget {
  final String detectedRuin; // Passed from ScannerCheatScreen

  const TrueARScreen({super.key, required this.detectedRuin});

  @override
  State<TrueARScreen> createState() => _TrueARScreenState();
}

class _TrueARScreenState extends State<TrueARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  bool _isPlacing = false;

  // 🌟 Map now only stores the BASE filename without the extension
  final Map<String, String> _ruinModelBaseNames = {
    'medirigiriya vatadage': 'royal_palace',
    'polonnaruwa vatadage': 'royal_palace',
    'royal palace of king parakramabahu': 'royal_palace',
    // Add all your YOLO class names here in lowercase mapping to their file base name
  };

  // 🌟 Dynamic platform branching logic
  String _getCorrect3DModelPath(String aiDetectedName) {
    String baseName = _ruinModelBaseNames[aiDetectedName] ?? 'default_info';

    if (Platform.isIOS) {
      // iOS Apple ARKit requirement
      return "assets/models/$baseName.usdz";
    } else {
      // Android ARCore requirement
      return "assets/models/$baseName.glb";
    }
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
    );
    this.arObjectManager!.onInitialize();
  }

  Future<void> _placeRuinModel() async {
    if (_isPlacing) return;
    setState(() => _isPlacing = true);

    try {
      // 1. Format the string passed from the scanner to match map keys
      String aiDetectedName = widget.detectedRuin.toLowerCase();

      // 2. Look up the assigned model URI dynamically based on iOS vs Android
      String assignedModelUri = _getCorrect3DModelPath(aiDetectedName);

      // 3. Get real-world camera position
      math.Matrix4? cameraPose = await arSessionManager!.getCameraPose();

      if (cameraPose != null) {
        // Position it 2 meters straight ahead and slightly down
        math.Vector3 localPosition = math.Vector3(0.0, -0.2, -2.0);
        math.Vector3 worldPosition = cameraPose.transform3(localPosition);

        var customNode = ARNode(
          type: NodeType.localGLTF2,
          uri: assignedModelUri,
          scale: math.Vector3(0.2, 0.2, 0.2),
          position: worldPosition,
          rotation: math.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        await arObjectManager!.addNode(customNode);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Anchored 3D model for ${widget.detectedRuin}!"),
              backgroundColor: Colors.orange, // Strict orange theme constraint applied
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Move your phone around slightly to track the environment first."),
              backgroundColor: Colors.orange, // Strict orange theme constraint applied
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("AR Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isPlacing = false);
      }
    }
  }

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("AR: ${widget.detectedRuin}"),
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        foregroundColor: Colors.orange, // Strict orange theme constraint applied
      ),
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
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                borderRadius: BorderRadius.circular(30),
                color: Colors.black.withOpacity(0.5),
                child: InkWell(
                  onTap: _isPlacing ? null : _placeRuinModel,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isPlacing
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)
                      )
                          : const Icon(Icons.view_in_ar, color: Colors.orange), // Strict orange theme constraint applied
                      const SizedBox(width: 12),
                      Text(
                        _isPlacing ? "Anchoring..." : "Place ${widget.detectedRuin} Model",
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16), // Strict orange theme constraint applied
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}