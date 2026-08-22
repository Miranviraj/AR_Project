import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. REUSABLE GLASSMORPHIC APP BAR ---
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const GlassAppBar({
    super.key,
    this.title = "Ancient Ceylon",
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.orange), // Strict orange theme applied
      centerTitle: false,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.account_balance, color: Colors.orange, size: 28);
              },
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              border: Border(
                bottom: BorderSide(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// --- 2. FEATURE-RICH APP DRAWER ---
class MainAppDrawer extends StatelessWidget {
  const MainAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF141E30), // Dark background to match app flow
      child: Column(
        children: [
          // Drawer Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              border: Border(
                bottom: BorderSide(color: Colors.orange.withOpacity(0.5), width: 2),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF141E30)),
                ),
                SizedBox(height: 16),
                Text(
                  "Explorer Profile",
                  style: TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "Level 5 Historian",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Drawer Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem(
                  icon: Icons.bookmarks,
                  title: "Saved Ruins",
                  onTap: () {
                    Navigator.pop(context); // Close Drawer
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedRuinsScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: "AI Chat History",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatHistoryScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download_for_offline,
                  title: "Offline 3D Models",
                  subtitle: "Manage downloaded AR assets",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OfflineModelsScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings_suggest,
                  title: "AR Calibration Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Divider(color: Colors.white24, thickness: 1),
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: "How to use AR Scanner",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: "Sign Out",
                  onTap: () async {
                    Navigator.pop(context);

                    // 🌟 Sign Out Logic
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully signed out!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      // Goes back to the first screen (Usually Login Screen)
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))
          : null,
      onTap: onTap,
      splashColor: Colors.orange.withOpacity(0.2),
    );
  }
}

// --- 3. NEW SEPARATE SCREENS ---

class SavedRuinsScreen extends StatelessWidget {
  const SavedRuinsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141E30),
      appBar: const GlassAppBar(title: "Saved Ruins"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmarks_outlined, size: 80, color: Colors.orange.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              "No saved ruins yet.\nStart scanning to save them here!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141E30),
      appBar: const GlassAppBar(title: "Chat History"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.orange.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              "Your AI guide conversations\nwill appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class OfflineModelsScreen extends StatelessWidget {
  const OfflineModelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141E30),
      appBar: const GlassAppBar(title: "Offline Models"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_in_ar_outlined, size: 80, color: Colors.orange.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              "No models downloaded.\nView ruins in AR to save models.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141E30),
      appBar: const GlassAppBar(title: "AR Settings"),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.speed, color: Colors.orange),
            title: const Text("Guide Speech Rate", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {},
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.high_quality, color: Colors.orange),
            title: const Text("AR Render Quality", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141E30),
      appBar: const GlassAppBar(title: "How to Use"),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AR Scanner Guide",
              style: TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildHelpStep(Icons.camera_alt, "1. Point your camera at a historical ruin."),
            _buildHelpStep(Icons.document_scanner, "2. Tap the 'Scan Ruin' button."),
            _buildHelpStep(Icons.view_in_ar, "3. Launch True AR to see the 3D reconstruction."),
            _buildHelpStep(Icons.chat_bubble, "4. Use the AI Guide to learn the history."),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}