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
        // 🌟 MODERN GLASS PALETTE
        scaffoldBackgroundColor: Colors.transparent, // Will be overridden by gradient backgrounds
        primaryColor: const Color(0xFFD4AF37), // Premium Gold Accents
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          surface: Color(0x33FFFFFF), // Transparent surface for default cards if any
          onSurface: Colors.white, 
        ),
        // Modern typography
        fontFamily: 'Roboto', // Or standard sans-serif
        
        // Style the navigation bar to match the sleek theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent, // Let glassmorphism show through
          selectedItemColor: Color(0xFFD4AF37), 
          unselectedItemColor: Colors.white54,
          elevation: 0,
        ),
      ),
      home: LoginScreen(camera: camera,),
    );
  }
}