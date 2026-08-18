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

class HomeDiscoveryScreen extends StatefulWidget {
  final CameraDescription camera;

  const HomeDiscoveryScreen({super.key, required this.camera});

  @override
  State<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends State<HomeDiscoveryScreen> {
  bool _isLoadingLocation = true;
  String _locationError = "";

  List<Map<String, dynamic>> _liveHeritageSites = [];

  @override
  void initState() {
    super.initState();
    _fetchLiveNearbySites();
  }

  Future<void> _fetchLiveNearbySites() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = "";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("GPS Disabled");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("Permission Denied");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final String wikiUrl =
          "https://en.wikipedia.org/w/api.php?action=query&generator=geosearch&ggscoord=${position.latitude}|${position.longitude}&ggsradius=10000&ggslimit=50&prop=pageimages|coordinates&pithumbsize=400&format=json";

      final response = await http.get(Uri.parse(wikiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>? ?? {};

        List<Map<String, dynamic>> fetchedSites = [];

        for (var page in pages.values) {
          String rawTitle = page['title'] ?? "";
          String title = rawTitle.toLowerCase();

          int heritageScore = 0;
          if (title.contains('vihara') || title.contains('stupa') ||
              title.contains('temple') || title.contains('ruin') ||
              title.contains('dagoba') || title.contains('aramaya') ||
              title.contains('pokuna') || title.contains('rock') ||
              title.contains('devalaya') || title.contains('kovil') ||
              title.contains('kotte') || title.contains('palace') ||
              title.contains('watadage')) {
            heritageScore = 100;
          }

          if (heritageScore == 0) continue;

          double siteLat = (page['coordinates']?[0]?['lat'] as num?)?.toDouble() ?? 0.0;
          double siteLon = (page['coordinates']?[0]?['lon'] as num?)?.toDouble() ?? 0.0;

          double distanceInMeters = Geolocator.distanceBetween(
              position.latitude, position.longitude, siteLat, siteLon
          );

          String formattedDistance;
          if (distanceInMeters >= 1000) {
            formattedDistance = "${(distanceInMeters / 1000).toStringAsFixed(1)} km away";
          } else {
            formattedDistance = "${distanceInMeters.toStringAsFixed(0)} m away";
          }

          fetchedSites.add({
            'name': rawTitle,
            'image': page['thumbnail']?['source'] ??
                'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/300px-No_image_available.svg.png',
            'distanceMeters': distanceInMeters,
            'distanceFormatted': formattedDistance,
            'score': heritageScore,
            'tag1': 'Ancient Site',
            'tag2': 'Verified',
            'lat': siteLat,
            'lon': siteLon,
          });
        }

        fetchedSites.sort((a, b) {
          int scoreComparison = b['score'].compareTo(a['score']);
          if (scoreComparison != 0) return scoreComparison;
          return a['distanceMeters'].compareTo(b['distanceMeters']);
        });

        setState(() {
          _liveHeritageSites = fetchedSites.take(4).toList();
          _isLoadingLocation = false;
        });
      } else {
        throw Exception("Web API Failed");
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Required for the glass effect to overlay the body
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
              // Featured Hero Card with fixed 4*2 aspect ratio
              AspectRatio(
                aspectRatio: 4 / 2,
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
                        Text('Featured Site', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Explore Ancient\nCeylon', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Scan Ruins Button Card
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
                        Icon(Icons.qr_code_scanner, size: 48, color: Color(0xFFD4AF37)),
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

              // Dynamic Live Data Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('Live Ruins Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (_isLoadingLocation) const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))),
                      )
                    ],
                  ),
                  TextButton(
                    onPressed: () => _fetchLiveNearbySites(),
                    child: const Icon(Icons.refresh, color: Color(0xFFD4AF37), size: 18),
                  )
                ],
              ),
              const SizedBox(height: 8),

              if (_locationError.isNotEmpty)
                Text('Connection Error: $_locationError', style: const TextStyle(color: Colors.redAccent)),

              if (!_isLoadingLocation && _liveHeritageSites.isEmpty && _locationError.isEmpty)
                const Text('No Wikipedia heritage sites found within 10km.', style: TextStyle(color: Colors.grey)),

              // Render list with formatted live distance
              if (!_isLoadingLocation && _liveHeritageSites.isNotEmpty)
                ..._liveHeritageSites.map((site) => _buildRuinsListItem(
                  context: context,
                  title: site['name'],
                  distance: site['distanceFormatted'],
                  tag1: site['tag1'],
                  tag2: site['tag2'],
                  imageUrl: site['image'],
                  lat: site['lat'],
                  lon: site['lon'],
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.blueGrey[900]),
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
        color: Colors.orange.withOpacity(0.3), // Solidified thematic constraint
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white70)),
    );
  }
}