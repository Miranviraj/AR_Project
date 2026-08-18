import 'package:ar/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // 🌟 1. Import the camera package


// 🌟 2. Make main() an async function
Future<void> main() async {
  // 🌟 3. Ensure Flutter is initialized before interacting with the device hardware
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 4. Fetch the list of available cameras on the device
  final cameras = await availableCameras();

  // 🌟 5. Grab the first camera (usually the back camera)
  final firstCamera = cameras.first;

  // 🌟 6. Pass the camera into your app
  runApp(HeritageARApp(camera: firstCamera));
}

class HeritageARApp extends StatelessWidget {
  final CameraDescription camera; // 🌟 7. Require the camera here too

  const HeritageARApp({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Heritage Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange, // Strictly maintaining the orange theme
        scaffoldBackgroundColor: Colors.white,
      ),
      // 🌟 8. Pass the camera down to the SplashScreen
      home: SplashScreen(camera: camera),
    );
  }
}