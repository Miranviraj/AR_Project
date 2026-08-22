import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final CameraDescription camera;

  const SplashScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();

    // Automatic navigation after 4 seconds if user doesn't tap
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(camera: widget.camera),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToLogin,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // 🌟 1. Custom Background Image
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/splash_bg.jpg'), // ඔයාගේ ෆොටෝ එකේ නම මෙතනට දෙන්න
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            // 🌟 2. Dark Overlay to make text readable and blend with the UI theme
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.orange.withOpacity(0.2), // Subtle theme tint
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🌟 Glassmorphism Container for Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported, color: Colors.orange, size: 80);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Ancient Ceylon AR',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange, // Title color aligned with theme
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Uncover History Through Augmented Reality',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),
                  OutlinedButton.icon(
                    onPressed: _navigateToLogin,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.withOpacity(0.8), width: 1.5),
                      backgroundColor: Colors.black.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.arrow_forward, color: Colors.orange),
                    label: const Text(
                      'Tap to Explore',
                      style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}