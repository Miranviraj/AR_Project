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

  double _searchRadiusKm = 50.0;

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

      await _fetchBackendNearbySites(position.latitude, position.longitude);

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
        title: const Text(' Map Explorer', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
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

                  // 🌟 FIX 1 & 2: Safely cast to double and increase dimensions to prevent overflow!
                  ..._monuments.map((site) => Marker(
                    point: LatLng(
                        (site['lat'] as num).toDouble(),
                        (site['lon'] as num).toDouble()
                    ),
                    width: 80,
                    height: 90,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _calculateAndDrawRoute(
                          LatLng(
                              (site['lat'] as num).toDouble(),
                              (site['lon'] as num).toDouble()
                          ),
                          site['name']
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange, width: 2.5),
                              color: const Color(0xFF141E30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: site['image_url'] != null && site['image_url'].toString().isNotEmpty
                                  ? Image.network(
                                site['image_url'],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.account_balance, color: Colors.orange, size: 20);
                                },
                              )
                                  : const Icon(Icons.account_balance, color: Colors.orange, size: 20),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: const Icon(Icons.arrow_drop_down, color: Colors.orange, size: 30),
                          ),
                        ],
                      ),
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
                      max: 300.0,
                      divisions: 295,
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
            bottom: 100,
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
        ], // 🌟 FIX 3: Cleaned up the stray brackets at the bottom
      ),
    );
  }
}