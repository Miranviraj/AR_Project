import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // 🌟 The Map UI
import 'package:latlong2/latlong.dart'; // ✅ No space!

class RuinDetailsScreen extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String distance;
  final double lat;
  final double lon;

  const RuinDetailsScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.distance,
    required this.lat,
    required this.lon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2118), // Deep Earth theme
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1C150F),
            iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD4AF37), // Antique Gold
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 18),
                      const SizedBox(width: 4),
                      Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Historical Significance",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "This ancient site is a testament to the architectural and spiritual heritage of ancient Ceylon. Scan this ruin with the Heritage AR camera to reconstruct its original glory and uncover forgotten history.",
                    style: TextStyle(fontSize: 16, color: Color(0xFFFDEDD4), height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  const Text(
                    "Site Location",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),

                  // 🌟 THE LIVE INLINE MAP!
                  Container(
                    height: 250, // How tall the map is on the screen
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5), width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lon), // Center the map on the ruin
                          initialZoom: 15.0, // Zoomed in enough to see the streets
                        ),
                        children: [
                          // 1. Load the actual map tiles from the web
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.miran.heritagear', // ✅ Unique and approved!
                          ),
                          // 2. Drop the pin on the exact location!
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lon),
                                width: 50,
                                height: 50,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}