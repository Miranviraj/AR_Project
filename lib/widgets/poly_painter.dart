import 'package:flutter/material.dart';

class RuinPolygonPainter extends CustomPainter {
  final List<Offset> normalizedPoints; // 🌟 0.0 ත් 1.0 ත් අතර අගයන්

  RuinPolygonPainter({required this.normalizedPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedPoints.isEmpty) return;

    final Path path = Path();

    // පළවෙනි ලක්ෂ්‍යයෙන් පටන් ගන්නවා (තිරයේ ප්‍රමාණයෙන් ගුණ කරලා සැබෑ තැන හොයනවා)
    path.moveTo(
        normalizedPoints.first.dx * size.width,
        normalizedPoints.first.dy * size.height
    );

    // ඉතුරු ලක්ෂ්‍ය ටික යා කරනවා
    for (int i = 1; i < normalizedPoints.length; i++) {
      path.lineTo(
          normalizedPoints[i].dx * size.width,
          normalizedPoints[i].dy * size.height
      );
    }
    path.close();

    // 🌟 1. ඇතුළත පාට කිරීම (Semi-transparent Orange)
    final Paint fillPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // 🌟 2. වටේ මායිම අඳින Glowing ඉර
    final Paint strokePaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4); // දිලිසෙන Effect එක

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}