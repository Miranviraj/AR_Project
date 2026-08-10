import 'package:flutter/material.dart';
import 'historical_contet.dart';
import '../widgets/glass_container.dart';

class ARReconstructionScreen extends StatelessWidget {
  const ARReconstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Simulated AR Background (Camera Feed + 3D Model)
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1620063165181-4206e23bb41c?q=80&w=1000&auto=format&fit=crop', // Placeholder for ruins background
              fit: BoxFit.cover,
            ),
          ),

          // Subtle Grid Overlay (Optional, for that "tech" feel)
          Positioned.fill(
            child: CustomPaint(painter: GridPainter()),
          ),

          // Top App Bar Elements
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Column(
                  children: [
                    const Text('Royal Palace Ruins', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
                    const SizedBox(height: 4),
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1),
                      child: const Text('AR LIVE VIEW', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () {
                      // Slide up the context panel
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const HistoricalContextPanel(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Simulated AR Hotspot 1
          Positioned(
            top: 300,
            left: 100,
            child: _buildHotspot(Icons.remove_red_eye),
          ),

          // Simulated AR Hotspot 2
          Positioned(
            top: 450,
            right: 80,
            child: _buildHotspot(Icons.history),
          ),

          // Bottom Controls Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.3), // A dark tint for the glass
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              border: Border.all(color: Colors.white12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Cards Row
                  Row(
                    children: [
                      Expanded(child: _buildActionCard(context, Icons.headphones, 'Audio Guide', '02:14 Remaining', true)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActionCard(context, Icons.layers, 'Reconstruct', 'Show original form', false)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Did You Know Card
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DID YOU KNOW?', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('This stone platform was once the foundation for a 7-story...', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const HistoricalContextPanel(),
                            );
                          },
                          child: const Text('Read More', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Camera Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomIcon(Icons.photo_library, 'Gallery'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD4AF37), width: 3),
                        ),
                        child: const Icon(Icons.camera, color: Colors.black, size: 32),
                      ),
                      _buildBottomIcon(Icons.qr_code_scanner, 'Scan'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspot(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Icon(icon, color: Colors.black, size: 20),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, bool isPlayable) {
    return GlassContainer(
      padding: const EdgeInsets.all(12),
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          if (isPlayable)
            const Icon(Icons.play_circle_fill, color: Color(0xFFD4AF37), size: 28),
        ],
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ],
    );
  }
}

// Simple Custom Painter for the AR Grid
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}