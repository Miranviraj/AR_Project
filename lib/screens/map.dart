import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ⚠️ CHANGE THIS TO YOUR LAPTOP'S IPV4 ADDRESS!
  static const String _backendUrl = 'http://192.168.X.X:8000/api/sites';

  LatLng? _currentLocation;
  List<dynamic> _heritageSites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    await _getUserLocation();
    await _fetchSitesFromBackend();
  }

  // 1. Get the user's live GPS location
  Future<void> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  // 2. Get the ruin coordinates from your Python AI Server
  Future<void> _fetchSitesFromBackend() async {
    try {
      final response = await http.get(Uri.parse(_backendUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _heritageSites = data['sites'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching sites: $e");
      setState(() => _isLoading = false);
    }
  }

  // 3. The trick to open Google Maps for Turn-by-Turn Navigation
  Future<void> _launchNavigation(double destLat, double destLng) async {
    final Uri googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng'
    );
    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  // 4. Show a pop-up when they tap a ruin on the map
  void _showSiteDetails(Map<String, dynamic> site) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2118),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                site['name'],
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 8),
              Text(
                site['description'],
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.directions_car, color: Colors.black),
                  label: const Text("Navigate Here", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context); // Close the popup
                    _launchNavigation(site['lat'], site['lng']); // Open Google Maps
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentLocation == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heritage Map'),
        backgroundColor: const Color(0xFF3A2E24),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _currentLocation!, // Center map on the user
          initialZoom: 8.0,
        ),
        children: [
          // The completely free OpenStreetMap layer!
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.ancient_ceylon',
          ),
          MarkerLayer(
            markers: [
              // 1. The Blue Marker for the User's Current Location
              Marker(
                point: _currentLocation!,
                width: 40,
                height: 40,
                child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
              ),

              // 2. The Gold Markers for all the Historical Sites
              ..._heritageSites.map((site) {
                return Marker(
                  point: LatLng(site['lat'], site['lng']),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _showSiteDetails(site),
                    child: const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 50),
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}