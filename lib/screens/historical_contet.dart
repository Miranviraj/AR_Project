import 'package:flutter/material.dart';

class HistoricalContextPanel extends StatelessWidget {
  const HistoricalContextPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrapped in a container to handle the bottom sheet styling
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF3A2E24), // Dark surface color
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Top Drag Indicator and App Bar
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.black26,
                      child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: IconButton(icon: const Icon(Icons.center_focus_strong, color: Colors.white), onPressed: () {}),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.black26,
                          child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    // Header Section
                    const Row(
                      children: [
                        Icon(Icons.account_balance, color: Color(0xFFD4AF37)),
                        SizedBox(width: 8),
                        Text('The Lion Gate', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('5th Century AD • Sigiriya Period', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 16),

                    // Tags
                    Row(
                      children: [
                        _buildTag('Architectural', true),
                        const SizedBox(width: 8),
                        _buildTag('UNESCO Site', false),
                        const SizedBox(width: 8),
                        _buildTag('Restored', false),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description Body
                    const Text(
                      'The Lion Gate is the main entrance to the palace complex atop the Sigiriya rock fortress. Originally, the entrance was through the open mouth of a gigantic brick and plaster lion.\n\nToday, only the two massive paws remain, flanking the staircase. This feature gave the rock its name, Sigiriya or Sihagiri, meaning "Lion Rock". The grandeur of this entrance served not only as a defensive measure but also as a symbolic representation of King Kashyapa\'s power and divine status.',
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 32),

                    // Blueprints Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.architecture, color: Color(0xFFD4AF37), size: 20),
                            SizedBox(width: 8),
                            Text('Blueprints & Sketches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        TextButton(onPressed: () {}, child: const Text('VIEW ALL', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Horizontal List of Sketches
                    SizedBox(
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildBlueprintCard('https://images.unsplash.com/photo-1595123550441-d3ccfd7e099c?q=80&w=500&auto=format&fit=crop', 'Sketch'),
                          const SizedBox(width: 12),
                          _buildBlueprintCard('https://images.unsplash.com/photo-1595123550441-d3ccfd7e099c?q=80&w=500&auto=format&fit=crop', '3D Model'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHighlighted ? const Color(0xFFD4AF37) : Colors.grey[700]!),
      ),
      child: Text(text, style: TextStyle(color: isHighlighted ? const Color(0xFFD4AF37) : Colors.grey[400], fontSize: 12)),
    );
  }

  Widget _buildBlueprintCard(String imageUrl, String label) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken), // Make image slightly darker
        ),
      ),
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      ),
    );
  }
}