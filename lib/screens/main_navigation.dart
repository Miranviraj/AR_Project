import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Make sure this is imported!
import 'home_discovery.dart';
import 'ar_scanner.dart'; // Make sure this points to your cheat screen
import '../widgets/glass_container.dart';

class MainNavigationScreen extends StatefulWidget {
  final CameraDescription camera;
  const MainNavigationScreen({super.key, required this.camera});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // 🌟 FIX 1: Turn this into a getter to safely access widget.camera
  // Also removed 'const' from HomeDiscoveryScreen
  List<Widget> get _screens => [
    HomeDiscoveryScreen(camera: widget.camera),
    const Center(child: Text('Map View')),
    const Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows body to scroll under the nav bar
      body: _screens[_currentIndex],
      bottomNavigationBar: GlassContainer(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).primaryColor,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.qr_code_scanner, color: Colors.black),
        onPressed: () {
          Navigator.push(
            context,
            // 🌟 FIX 2: Added 'widget.' and removed 'const' here
            MaterialPageRoute(builder: (context) => ScannerCheatScreen(camera: widget.camera)),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}