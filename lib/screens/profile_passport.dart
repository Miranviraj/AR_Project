import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_container.dart';

class ProfilePassportScreen extends StatefulWidget {
  const ProfilePassportScreen({super.key});

  @override
  State<ProfilePassportScreen> createState() => _ProfilePassportScreenState();
}

class _ProfilePassportScreenState extends State<ProfilePassportScreen> {
  List<String> unlockedSites = [];

  @override
  void initState() {
    super.initState();
    _loadPassport();
  }

  Future<void> _loadPassport() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // It reads the list of sites you have scanned!
      unlockedSites = prefs.getStringList('unlocked_sites') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Explorer Passport', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sites Discovered: ${unlockedSites.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 20),

            // The Stamps
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStamp('Abhayagiri Vihāra', unlockedSites.contains('Abhayagiri Vihāra')),
                  _buildStamp('Jetavanaramaya', unlockedSites.contains('Jetavanaramaya')),
                  _buildStamp('Sandakada Pahana', unlockedSites.contains('Sandakada Pahana')),
                  _buildStamp('Ruwanwelisaya', unlockedSites.contains('Ruwanwelisaya')),
                ],
              ),
            ),

            // The Physical Reward Tie-in
            GlassContainer(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
              child: const Row(
                children: [
                  Icon(Icons.card_giftcard, color: Color(0xFFD4AF37), size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Unlock 4 sites to claim your exclusive heritage-inspired coconut shell key tag at the visitor center!',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStamp(String name, bool isUnlocked) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: isUnlocked ? const Color(0xFFD4AF37) : Colors.grey, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance, size: 40, color: isUnlocked ? const Color(0xFFD4AF37) : Colors.grey),
            const SizedBox(height: 8),
            Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isUnlocked ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }
}