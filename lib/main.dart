import 'package:ar/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // 🌟 Added camera import
import 'screens/main_navigation.dart';

// 🌟 FIX 1: Make main() async to turn on the camera hardware first
Future<void> main() async {
  // Ensure Flutter is fully initialized before talking to the hardware
  WidgetsFlutterBinding.ensureInitialized();

  // Get the list of available cameras on the device
  final cameras = await availableCameras();

  // Grab the very first camera (which is always the back camera)
  final firstCamera = cameras.first;

  // Pass it into your app
  runApp(HeritageARApp(camera: firstCamera));
}

class HeritageARApp extends StatelessWidget {
  final CameraDescription camera;

  const HeritageARApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heritage AR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // 🌟 NEW ANCIENT PALETTE
        scaffoldBackgroundColor: const Color(0xFF2A2118), // Deep Earth Brown
        primaryColor: const Color(0xFFD4AF37), // Antique Gold
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37), // Gold Accents
          surface: Color(0xFF3A2E24), // Carved Stone/Wood for Cards
          onSurface: Color(0xFFFDEDD4), // Parchment off-white for text
        ),
        // 🌟 A classic serif font gives an instant historical/museum feel
        fontFamily: 'Georgia',

        // Style the navigation bar to match the ancient theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1C150F), // Very dark earth
          selectedItemColor: Color(0xFFD4AF37), // Gold
          unselectedItemColor: Colors.white54,
        ),
      ),
      home: LoginScreen(camera: camera,),
    );
  }
}