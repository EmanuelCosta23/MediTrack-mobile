import 'package:flutter/material.dart';

class MediTrackLogo extends StatelessWidget {
  final double size;
  final Color color;

  const MediTrackLogo({
    Key? key,
    this.size = 32.0,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MediTrackLogoPainter(color: color),
    );
  }
}

class _MediTrackLogoPainter extends CustomPainter {
  final Color color;

  _MediTrackLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height * 0.42);
    final radius = size.width * 0.28;
    
    // Outer partial circle (left arc)
    final leftArcRect = Rect.fromCircle(center: center, radius: radius * 1.3);
    canvas.drawArc(
      leftArcRect,
      2.7, // Starting angle in radians
      1.8, // Sweep angle in radians
      false,
      paint,
    );
    
    // Outer partial circle (right arc)
    canvas.drawArc(
      leftArcRect,
      5.0, // Starting angle in radians
      1.8, // Sweep angle in radians
      false,
      paint,
    );

    // Main circle
    canvas.drawCircle(center, radius, paint);

    // Cross (horizontal)
    canvas.drawLine(
      Offset(center.dx - radius * 0.5, center.dy),
      Offset(center.dx + radius * 0.5, center.dy),
      paint,
    );

    // Cross (vertical)
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.5),
      Offset(center.dx, center.dy + radius * 0.5),
      paint,
    );

    // Small circle
    final smallCircleCenter = Offset(
      center.dx + radius * 1.3 - paint.strokeWidth / 2,
      center.dy + radius * 0.2,
    );
    canvas.drawCircle(smallCircleCenter, size.width * 0.05, paint);

    // Handle/stem
    final stemPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final stemPath = Path()
      ..moveTo(center.dx - radius * 0.2, center.dy + radius * 1.0)
      ..lineTo(center.dx + radius * 0.2, center.dy + radius * 1.0)
      ..lineTo(center.dx, center.dy + radius * 0.7)
      ..close();
    canvas.drawPath(stemPath, stemPaint);
    
    // Bottom handle
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 1.4),
        width: size.width * 0.16,
        height: size.height * 0.16,
      ),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(handleRect, stemPaint);
  }

  @override
  bool shouldRepaint(_MediTrackLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
} 