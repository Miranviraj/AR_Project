import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "Explorer Profile";
  String _userLevel = "Level 5 Historian";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // 🌟 1. Load User Info from Local Storage
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? "Explorer Profile";
    });
  }

  // 🌟 2. Show Saved Ruins (Working Function)
  Future<void> _showSavedRuins() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedSites = prefs.getStringList('unlocked_sites') ?? [];

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E232D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Saved Ruins",
                style: TextStyle(color: Colors.orange, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              savedSites.isEmpty
                  ? const Text("No ruins saved yet. Start scanning!", style: TextStyle(color: Colors.white70))
                  : Expanded(
                child: ListView.builder(
                  itemCount: savedSites.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.account_balance, color: Colors.orange),
                      title: Text(savedSites[index], style: const TextStyle(color: Colors.white)),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🌟 3. Show Offline 3D Models (Working Function for iOS .usdz files)
  Future<void> _showOfflineModels() async {
    List<FileSystemEntity> downloadedFiles = [];
    try {
      final dir = await getTemporaryDirectory();
      downloadedFiles = dir.listSync().where((file) => file.path.endsWith('.usdz')).toList();
    } catch (e) {
      debugPrint("Error loading files: $e");
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E232D),
          title: const Text("Offline 3D Models", style: TextStyle(color: Colors.orange)),
          content: SizedBox(
            width: double.maxFinite,
            child: downloadedFiles.isEmpty
                ? const Text("No models downloaded yet.", style: TextStyle(color: Colors.white70))
                : ListView.builder(
              shrinkWrap: true,
              itemCount: downloadedFiles.length,
              itemBuilder: (context, index) {
                String fileName = downloadedFiles[index].path.split('/').last;
                return ListTile(
                  leading: const Icon(Icons.view_in_ar, color: Colors.orange),
                  title: Text(fileName, style: const TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.orange),
                    onPressed: () {
                      downloadedFiles[index].deleteSync();
                      Navigator.pop(context);
                      _showOfflineModels(); // Refresh
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.orange)),
            )
          ],
        );
      },
    );
  }

  // 🌟 4. Calibration Settings (Placeholder Slider)
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E232D),
        title: const Text("AR Settings", style: TextStyle(color: Colors.orange)),
        content: const Text("Voice Guide Speed and AR Quality settings will be configured here.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK", style: TextStyle(color: Colors.orange)))
        ],
      ),
    );
  }

  // 🌟 5. Sign Out Function
  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data/tokens

    if (!mounted) return;
    // ආපහු Login Screen එකට යවනවා (ඔයාගේ LoginScreen එකේ නම දෙන්න)
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Signed out successfully!"), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181C24), // Dark background from your screenshot
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 Top Profile Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, size: 50, color: Color(0xFF181C24)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName,
                    style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userLevel,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.orange, thickness: 1),

            // 🌟 Menu Items
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(Icons.bookmark, "Saved Ruins", onTap: _showSavedRuins),
                  _buildMenuItem(Icons.history, "AI Chat History", onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat History coming soon!"), backgroundColor: Colors.orange));
                  }),
                  _buildMenuItem(Icons.download_for_offline, "Offline 3D Models", subtitle: "Manage downloaded AR assets", onTap: _showOfflineModels),
                  _buildMenuItem(Icons.settings, "AR Calibration Settings", onTap: _showSettings),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Divider(color: Colors.white24, thickness: 1, height: 40),
                  ),

                  _buildMenuItem(Icons.help_outline, "How to use AR Scanner", onTap: () {}),
                  _buildMenuItem(Icons.logout, "Sign Out", onTap: _signOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom Widget for Menu Items
  Widget _buildMenuItem(IconData icon, String title, {String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: Colors.orange, size: 28),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14)) : null,
      onTap: onTap,
    );
  }
}