import 'package:ar/screens/profile_passport.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'chat_guide.dart';
import 'home_discovery.dart';
import 'ar_scanner.dart';
import '../widgets/glass_container.dart';
import 'map.dart';

class MainNavigationScreen extends StatefulWidget {
  final CameraDescription camera;
  const MainNavigationScreen({super.key, required this.camera});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 🌟 Initial screen coordinates for the movable chat button
  Offset _chatButtonOffset = const Offset(20, 120);

  List<Widget> get _screens => [
    HomeDiscoveryScreen(camera: widget.camera),
    HeritageExplorerMapScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. Main active tab view
          _screens[_currentIndex],

          // 2. 🌟 Draggable Chat Guide Button
          Positioned(
            left: _chatButtonOffset.dx,
            top: _chatButtonOffset.dy,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Calculate new drag coordinates
                  double newX = _chatButtonOffset.dx + details.delta.dx;
                  double newY = _chatButtonOffset.dy + details.delta.dy;

                  // Keep button within visible screen boundaries
                  newX = newX.clamp(0.0, screenSize.width - 60.0);
                  newY = newY.clamp(0.0, screenSize.height - 140.0);

                  _chatButtonOffset = Offset(newX, newY);
                });
              },
              child: FloatingActionButton(
                heroTag: "movable_chat_btn", // Unique hero tag to prevent conflicts
                backgroundColor: Colors.orange, // Matching orange theme
                elevation: 6,
                child: const Icon(Icons.chat_bubble, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatGuideScreen(recognizedArtifact: ''),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: GlassContainer(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),

    );
  }
}