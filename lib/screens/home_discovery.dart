import 'package:ar/screens/chat_guide.dart';
import 'package:ar/screens/details.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_bar_drawer.dart';
import '../widgets/glass_container.dart';
import 'ar_reconstruction.dart';
import '../const/api_config.dart';
import 'ar_scanner.dart';

class HomeDiscoveryScreen extends StatefulWidget {
  final CameraDescription camera;

  const HomeDiscoveryScreen({super.key, required this.camera});

  @override
  State<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends State<HomeDiscoveryScreen> {
  // Cleaned up duplicate state variables
  List<dynamic> _liveRuins = [];
  bool _isLoading = true;
  String _locationError = "";

  @override
  void initState() {
    super.initState();
    fetchLiveRuins();
  }

  Future<void> fetchLiveRuins() async {
    setState(() {
      _isLoading = true;
      _locationError = "";
    });

    try {
      // 1. Fetch exact GPS location dynamically
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLat = position.latitude;
      double userLon = position.longitude;

      // 2. Pass dynamic coordinates to the nearby-sites endpoint
      final url = Uri.parse('${ApiConfig().baseUrl}/api/nearby-sites?user_lat=$userLat&user_lon=$userLon&radius_km=500.0');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // 3. Update the correct list
          _liveRuins = data['sites'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _locationError = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching ruins: $e");
      setState(() {
        _locationError = "Failed to load data. Check backend connection.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        title: "Ancient Ceylon AR",
      ),
      drawer: const MainAppDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 2, // Maintained exact aspect ratio parameter
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2E24),
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage('assets/banner.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    alignment: Alignment.bottomLeft,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Applied strict orange theme
                        Text('Featured Site', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Explore Ancient\nCeylon', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScannerCheatScreen(camera: widget.camera)),
                  );
                },
                child: const GlassContainer(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 48, color: Colors.orange), // Applied strict orange theme
                        SizedBox(height: 12),
                        Text('Scan Ruins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Point your camera to identify structures', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Live Ruins Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (_isLoading) const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange)),
                      )
                    ],
                  ),
                  TextButton(
                    // Fixed refresh button routing to correct method
                    onPressed: () => fetchLiveRuins(),
                    child: const Icon(Icons.refresh, color: Colors.orange, size: 18),
                  )
                ],
              ),
              const SizedBox(height: 8),

              if (_locationError.isNotEmpty)
                Text('Connection Error: $_locationError', style: const TextStyle(color: Colors.redAccent)),

              if (!_isLoading && _liveRuins.isEmpty && _locationError.isEmpty)
                const Text('No heritage sites found in the database.', style: TextStyle(color: Colors.grey)),

              // Successfully map the backend response to the UI
              if (!_isLoading && _liveRuins.isNotEmpty)
                ..._liveRuins.map((site) => _buildRuinsListItem(
                  context: context,
                  title: site['name'] ?? 'Unknown',
                  distance: "${site['distance_km']} km away",
                  tag1: 'Heritage DB',
                  tag2: 'Verified',
                  imageUrl: site['image_url'] ?? '',
                  lat: site['lat'] ?? 0.0,
                  lon: site['lon'] ?? 0.0,
                  description: site['description'] ?? 'No description available',
                )),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuinsListItem({
    required BuildContext context,
    required String title,
    required String distance,
    required String tag1,
    required String tag2,
    required String imageUrl,
    required double lat,
    required double lon,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.blueGrey[900]),
            )
                : Container(
              width: 60,
              height: 60,
              color: Colors.blueGrey[900],
              child: const Icon(Icons.image_not_supported, color: Colors.orange, size: 20),
            ),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    distance,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTag(tag1),
                  const SizedBox(width: 8),
                  _buildTag(tag2),
                ],
              )
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RuinDetailsScreen(
                  title: title,
                  imageUrl: imageUrl,
                  lat: lat,
                  lon: lon,
                  description: description,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    );
  }
}