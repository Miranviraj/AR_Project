import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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
  String _statusText = "Start AR Experience";

  Future<void> _launchNativeAR() async {
    setState(() {
      _isLaunching = true;
      _statusText = "Processing AR..";
    });

    try {
      String rawUrl = widget.modelUrl;
      if (rawUrl.endsWith('.usdz')) {
        rawUrl = rawUrl.substring(0, rawUrl.length - 5);
      } else if (rawUrl.endsWith('.glb')) {
        rawUrl = rawUrl.substring(0, rawUrl.length - 4);
      }

      if (Platform.isAndroid) {
        final String androidUrl = '$rawUrl.glb';
        final String encodedUrl = Uri.encodeComponent(androidUrl);
        final String encodedTitle = Uri.encodeComponent(widget.detectedRuin);

        final String intentUrl = 'intent://arvr.google.com/scene-viewer/1.0?file=$encodedUrl&title=$encodedTitle&mode=ar_only&resizable=true#Intent;scheme=https;package=com.google.ar.core;action=android.intent.action.VIEW;S.browser_fallback_url=https://developers.google.com/ar;end;';

        try {
          await launchUrl(Uri.parse(intentUrl), mode: LaunchMode.externalApplication);
        } catch (e) {
          final Uri fallbackUri = Uri.parse('https://arvr.google.com/scene-viewer/1.0?file=$encodedUrl&title=$encodedTitle&mode=ar_only');
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        }

      } else if (Platform.isIOS) {
        setState(() { _statusText = "Downloading iOS Model..."; });

        final String iosUrl = '$rawUrl.usdz';
        final response = await http.get(Uri.parse(iosUrl));

        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final safeName = widget.detectedRuin.replaceAll(' ', '_');
          final localFile = File('${dir.path}/$safeName.usdz');

          await localFile.writeAsBytes(response.bodyBytes);

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
          _statusText = "Start AR Experience";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/banner.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

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
                  "${widget.detectedRuin} Detected!",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Click Below Button For AR",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

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