import 'package:flutter/material.dart';

/// Icône plume (reprise du glyphe "Feather" de Lucide, utilisé par
/// AviBreed Pro pour représenter les oiseaux) — trait fin (outline) ou
/// plein (filled), pour coller au style des autres icônes de la barre.
class FeatherIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool filled;

  const FeatherIcon({super.key, this.size = 24, this.color, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.black;
    return CustomPaint(
      size: Size(size, size),
      painter: _FeatherPainter(c, filled),
    );
  }
}

class _FeatherPainter extends CustomPainter {
  final Color color;
  final bool filled;
  _FeatherPainter(this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    canvas.scale(s, s);

    final body = Path()
      ..moveTo(20.24, 12.24)
      ..arcToPoint(const Offset(11.75, 3.75), radius: const Radius.circular(6), clockwise: false)
      ..lineTo(5, 10.5)
      ..lineTo(5, 19)
      ..lineTo(13.5, 19)
      ..close();

    if (filled) {
      canvas.drawPath(body, Paint()..color = color..style = PaintingStyle.fill);
      final quill = Path()
        ..moveTo(16, 8)
        ..lineTo(2, 22)
        ..lineTo(3.4, 23.4)
        ..lineTo(17, 9.4)
        ..close();
      canvas.drawPath(quill, Paint()..color = color..style = PaintingStyle.fill);
    } else {
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(body, stroke);
      canvas.drawLine(const Offset(16, 8), const Offset(2, 22), stroke);
      canvas.drawLine(const Offset(17.5, 15), const Offset(9, 15), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _FeatherPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.filled != filled;
}
