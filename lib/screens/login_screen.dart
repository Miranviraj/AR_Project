import 'package:ar/screens/main_navigation.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../const/api_config.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final CameraDescription camera; // 🌟 Accept the camera here

  const LoginScreen({super.key, required this.camera});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ⚠️ USE YOUR ACTUAL BACKEND IP ADDRESS HERE
  final String _authUrl = '${ApiConfig().baseUrl}/api/login';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackbar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSnackbar(data['message']);

        if (data['success'] == true) {
          String username = data['username'];
          String token = data['token'];

          print("Logged in successfully as $username with token: $token");

          // 🌟 Access the passed camera using widget.camera
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MainNavigationScreen(camera: widget.camera)
            ),
          );
        }
      } else {
        _showSnackbar("Invalid email or password.");
      }
    } catch (e) {
      _showSnackbar("Could not connect to backend server.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2118),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance, size: 80, color: Color(0xFFD4AF37)),
              const SizedBox(height: 20),
              const Text("Ancient Ceylon AR", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _handleLogin,
                  child: const Text("Sign In", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                },
                child: const Text("Don't have an account? Register here", style: TextStyle(color: Color(0xFFD4AF37))),
              )
            ],
          ),
        ),
      ),
    );
  }
}