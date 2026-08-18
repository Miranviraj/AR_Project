import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/glass_container.dart';
import 'map.dart';

class RuinDetailsScreen extends StatefulWidget {
  final String title;
  final String imageUrl;
  final double lat;
  final double lon;
  final String description; // 🌟 Accept the database description directly

  const RuinDetailsScreen({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.lat,
    required this.lon,
    required this.description,
  });

  @override
  State<RuinDetailsScreen> createState() => _RuinDetailsScreenState();
}

class _RuinDetailsScreenState extends State<RuinDetailsScreen> {
  String liveDistance = "Calculating real distance...";

  @override
  void initState() {
    super.initState();
    _calculateRealDistance();
  }

  Future<void> _calculateRealDistance() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => liveDistance = "Location services disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => liveDistance = "Location permission denied");
        return;
      }
    }

    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );

    final Distance distanceCalculator = const Distance();
    final double meters = distanceCalculator.as(
      LengthUnit.Meter,
      LatLng(currentPosition.latitude, currentPosition.longitude),
      LatLng(widget.lat, widget.lon),
    );

    setState(() {
      if (meters > 1000) {
        liveDistance = "${(meters / 1000).toStringAsFixed(1)} km away from you";
      } else {
        liveDistance = "${meters.toStringAsFixed(0)} meters away from you";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.orange),
              flexibleSpace: FlexibleSpaceBar(
                background: widget.imageUrl.isNotEmpty
                    ? Image.network(widget.imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.blueGrey[900]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          liveDistance,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Historical Significance",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    // 🌟 Displaying the description directly from the backend database
                    Text(
                      widget.description,
                      style: const TextStyle(fontSize: 16, color: Color(0xFFFDEDD4), height: 1.5),
                    ),

                    const SizedBox(height: 32),
                    const Text(
                      "Site Location",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.explore, color: Colors.white),
                      label: const Text(
                        "Open Live Navigation Map",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HeritageExplorerMapScreen(
                              targetLat: widget.lat,
                              targetLon: widget.lon,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    GlassContainer(
                      padding: const EdgeInsets.all(0),
                      borderRadius: BorderRadius.circular(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 4 / 2,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(widget.lat, widget.lon),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.miran.heritagear',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(widget.lat, widget.lon),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.orange,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}