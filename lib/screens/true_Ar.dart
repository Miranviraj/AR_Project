import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../widgets/glass_container.dart';

class TrueARScreen extends StatefulWidget {
  final String detectedRuin;
  final String modelUrl;

  const TrueARScreen({
    super.key,
    required this.detectedRuin,
    required this.modelUrl,
  });

  @override
  State<TrueARScreen> createState() => _TrueARScreenState();
}

class _TrueARScreenState extends State<TrueARScreen> {
  bool _isLaunching = false;

  // 🌟 NATIVE AR LAUNCHER: This is 100% crash-proof and identical to iPhone's smoothness
  Future<void> _launchNativeAR() async {
    setState(() {
      _isLaunching = true;
    });

    try {
      if (Platform.isAndroid) {
        // ANDROID: Launch Google Scene Viewer
        final String encodedUrl = Uri.encodeComponent(widget.modelUrl);
        final String encodedTitle = Uri.encodeComponent(widget.detectedRuin);

        // This invokes the exact screen you sent in your screenshot!
        final Uri intentUri = Uri.parse(
            'https://arvr.google.com/scene-viewer/1.0?file=$encodedUrl&title=$encodedTitle&mode=ar_only&resizable=true'
        );

        if (await canLaunchUrl(intentUri)) {
          await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch AR Viewer';
        }
      } else if (Platform.isIOS) {
        // IOS: Launch AR Quick Look
        final String iosUrl = widget.modelUrl.replaceAll('.glb', '.usdz');
        final Uri iosUri = Uri.parse(iosUrl);

        if (await canLaunchUrl(iosUri)) {
          await launchUrl(iosUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch iOS AR';
        }
      }
    } catch (e) {
      debugPrint("AR Launch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error launching AR: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sleek black background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.detectedRuin),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image (You can change this to a picture of the ruin)
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'Images/triangle.png', // Change this to a beautiful background if you want
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.view_in_ar_rounded,
                  size: 100,
                  color: Colors.orange.withOpacity(0.8),
                ),
                const SizedBox(height: 20),
                Text(
                  "${widget.detectedRuin} හඳුනාගත්තා!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "AR අත්දැකීම ලබාගැනීමට පහත බොත්තම ඔබන්න",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Launch AR Button at the bottom
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: GlassContainer( // Your custom Glass UI
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              borderRadius: BorderRadius.circular(30),
              color: Colors.black.withOpacity(0.6),
              child: InkWell(
                onTap: _isLaunching ? null : _launchNativeAR,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isLaunching
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
                    )
                        : const Icon(Icons.play_arrow_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      _isLaunching ? "AR සූදානම් වෙමින් පවතී..." : "AR අත්දැකීම අරඹන්න",
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}