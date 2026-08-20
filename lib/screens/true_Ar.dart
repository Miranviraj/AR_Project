import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart'; // 🌟 Added for OpenFilex and ResultType
import 'package:http/http.dart' as http;
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
  String _statusText = "AR අත්දැකීම අරඹන්න"; // 🌟 Defined the status text variable

  // 🌟 NATIVE AR LAUNCHER: Deep Link Intent (Bypasses Chrome Completely!)
  Future<void> _launchNativeAR() async {
    setState(() {
      _isLaunching = true;
      _statusText = "AR සූදානම් වෙමින් පවතී...";
    });

    try {
      // Clean URL Extension
      String rawUrl = widget.modelUrl;
      if (rawUrl.endsWith('.usdz')) {
        rawUrl = rawUrl.substring(0, rawUrl.length - 5);
      } else if (rawUrl.endsWith('.glb')) {
        rawUrl = rawUrl.substring(0, rawUrl.length - 4);
      }

      if (Platform.isAndroid) {
        // ANDROID: Launch Google Scene Viewer via Intent (Bypass Browser)
        final String androidUrl = '$rawUrl.glb';
        final String encodedUrl = Uri.encodeComponent(androidUrl);
        final String encodedTitle = Uri.encodeComponent(widget.detectedRuin);

        // 🌟 THE MAGIC FIX: Android Intent URL
        final String intentUrl = 'intent://arvr.google.com/scene-viewer/1.0?file=$encodedUrl&title=$encodedTitle&mode=ar_only&resizable=true#Intent;scheme=https;package=com.google.ar.core;action=android.intent.action.VIEW;S.browser_fallback_url=https://developers.google.com/ar;end;';

        try {
          // Launch the Intent directly
          await launchUrl(Uri.parse(intentUrl), mode: LaunchMode.externalApplication);
        } catch (e) {
          // Fallback if the intent completely fails
          final Uri fallbackUri = Uri.parse('https://arvr.google.com/scene-viewer/1.0?file=$encodedUrl&title=$encodedTitle&mode=ar_only');
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }

      } else if (Platform.isIOS) {
        // IOS: Bypass HTTP restriction by downloading locally first
        setState(() { _statusText = "Downloading iOS Model..."; });

        final String iosUrl = '$rawUrl.usdz';
        final response = await http.get(Uri.parse(iosUrl));

        if (response.statusCode == 200) {
          // Save to temporary directory
          final dir = await getTemporaryDirectory();
          final safeName = widget.detectedRuin.replaceAll(' ', '_');
          final localFile = File('${dir.path}/$safeName.usdz');

          await localFile.writeAsBytes(response.bodyBytes);

          // Launch local USDZ file natively using open_filex
          final result = await OpenFilex.open(localFile.path);
          if (result.type != ResultType.done) {
            throw 'Error opening AR file: ${result.message}';
          }
        } else {
          throw 'Download failed. Status: ${response.statusCode}';
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
          _statusText = "AR අත්දැකීම අරඹන්න";
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
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'Images/triangle.png', // Background image
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
            child: GlassContainer(
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
                      _statusText,
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