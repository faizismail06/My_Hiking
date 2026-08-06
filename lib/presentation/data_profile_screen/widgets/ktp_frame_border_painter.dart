import 'dart:ui';
import 'package:flutter/material.dart';

class KtpFrameBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  KtpFrameBorderPainter({
    this.color = const Color(0xFF2E7D32),
    this.strokeWidth = 2.0,
    this.cornerLength = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    // Draw background dashed border
    _drawDashedRRect(canvas, rrect, paint);

    // Draw highlighted corner brackets
    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth + 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 16.0;
    final w = size.width;
    final h = size.height;

    // Top-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(0, r + cornerLength)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(r + cornerLength, 0),
      cornerPaint,
    );

    // Top-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(w - r - cornerLength, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, r + cornerLength),
      cornerPaint,
    );

    // Bottom-Left Corner
    canvas.drawPath(
      Path()
        ..moveTo(0, h - r - cornerLength)
        ..lineTo(0, h - r)
        ..quadraticBezierTo(0, h, r, h)
        ..lineTo(r + cornerLength, h),
      cornerPaint,
    );

    // Bottom-Right Corner
    canvas.drawPath(
      Path()
        ..moveTo(w - r - cornerLength, h)
        ..lineTo(w - r, h)
        ..quadraticBezierTo(w, h, w, h - r)
        ..lineTo(w, h - r - cornerLength),
      cornerPaint,
    );
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    const double dashWidth = 8.0;
    const double dashSpace = 5.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashPath.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
