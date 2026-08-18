import 'dart:ui';
import 'package:flutter/material.dart';

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
          // 🌟 Replaced Icon with Image.asset for the App Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(6), // Slightly rounds the corners of your icon
            child: Image.asset(
              'assets/icon.png', // Make sure this matches your image name in the assets folder!
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback just in case the image fails to load
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
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.history,
                  title: "AI Chat History",
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.download_for_offline,
                  title: "Offline 3D Models",
                  subtitle: "Manage downloaded AR assets",
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.settings_suggest,
                  title: "AR Calibration Settings",
                  onTap: () {},
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Divider(color: Colors.white24, thickness: 1),
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: "How to use AR Scanner",
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: "Sign Out",
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to keep list items consistent
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