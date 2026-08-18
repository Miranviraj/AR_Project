import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../const/api_config.dart';

class HeritageExplorerMapScreen extends StatefulWidget {
  final double? targetLat;
  final double? targetLon;

  const HeritageExplorerMapScreen({super.key, this.targetLat, this.targetLon});

  @override
  _HeritageExplorerMapScreenState createState() => _HeritageExplorerMapScreenState();
}

class _HeritageExplorerMapScreenState extends State<HeritageExplorerMapScreen> {
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  List<Map<String, dynamic>> _monuments = [];
  List<LatLng> _routePoints = [];
  String _activeRouteDistance = "";
  String _activeSiteName = "Select a site to route";
  bool _isLoading = true;

  // Dynamic search radius state (5.0 km to 100.0 km)
  double _searchRadiusKm = 50.0;

  // Replace with your active Google Cloud Server IP
  final String serverIp = '${ApiConfig().baseUrl}';

  @override
  void initState() {
    super.initState();
    _getUserLocationAndFetchSites();
  }

  Future<void> _getUserLocationAndFetchSites() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = userLatLng;
      });

      // 1. Fetch nearby sites from custom Python backend
      await _fetchBackendNearbySites(position.latitude, position.longitude);

      // 2. If opened from detail screen, draw initial route
      if (widget.targetLat != null && widget.targetLon != null) {
        _calculateAndDrawRoute(LatLng(widget.targetLat!, widget.targetLon!), "Selected Ruin");
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchBackendNearbySites(double lat, double lon) async {
    final url = Uri.parse('$serverIp/api/nearby-sites?user_lat=$lat&user_lon=$lon&radius_km=$_searchRadiusKm');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> loadedSites = List<Map<String, dynamic>>.from(data['sites']);

        setState(() {
          _monuments = loadedSites;
        });
      }
    } catch (e) {
      debugPrint("Error fetching backend sites: $e");
    }
  }

  Future<void> _calculateAndDrawRoute(LatLng destination, String siteName) async {
    if (_userLocation == null) return;

    final Distance distance = const Distance();
    final double km = distance.as(LengthUnit.Kilometer, _userLocation!, destination);

    setState(() {
      _activeRouteDistance = "${km.toStringAsFixed(1)} km away";
      _activeSiteName = siteName;
    });

    final url = 'https://router.project-osrm.org/route/v1/driving/${_userLocation!.longitude},${_userLocation!.latitude};${destination.longitude},${destination.latitude}?geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'];

        List<LatLng> route = [];
        for (var coord in coordinates) {
          route.add(LatLng(coord[1], coord[0]));
        }

        setState(() {
          _routePoints = route;
        });

        _mapController.move(destination, 14.0);
      }
    } catch (e) {
      debugPrint("Routing error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Map Explorer', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141E30),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: _isLoading || _userLocation == null
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation!,
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.miran.heritagear',
              ),
              PolylineLayer(
                polylines: [
                  // 🌟 FIX: Only render the polyline if we actually have route points
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.orange.withOpacity(0.8),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // User GPS Location Marker
                  Marker(
                    point: _userLocation!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.my_location, color: Colors.blueAccent, size: 35),
                  ),
                  // Dynamic Markers from Backend
                  ..._monuments.map((site) => Marker(
                    point: LatLng(site['lat'], site['lon']),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _calculateAndDrawRoute(
                          LatLng(site['lat'], site['lon']),
                          site['name']
                      ),
                      child: const Icon(Icons.location_on, color: Colors.orange, size: 40),
                    ),
                  )).toList(),
                ],
              ),
            ],
          ),

          // Interactive Radius Filter Panel Overlay (Top)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141E30).withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.radar, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Search Radius",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          "${_searchRadiusKm.toInt()} km",
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.orange,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.orange,
                      overlayColor: Colors.orange.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _searchRadiusKm,
                      min: 5.0,
                      max: 100.0,
                      divisions: 95,
                      label: "${_searchRadiusKm.toInt()} km",
                      onChanged: (newValue) {
                        setState(() {
                          _searchRadiusKm = newValue;
                        });
                      },
                      onChangeEnd: (finalValue) {
                        if (_userLocation != null) {
                          _fetchBackendNearbySites(_userLocation!.latitude, _userLocation!.longitude);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Information overlay (Bottom)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141E30).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _activeSiteName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeRouteDistance.isEmpty ? "Tap any orange monument marker to draw route" : _activeRouteDistance,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}