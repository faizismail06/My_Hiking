import 'package:flutter/material.dart';

enum LivenessStep {
  positioning,
  blink,
  smile,
  completed,
}

class FaceOvalPainter extends CustomPainter {
  final Color borderColor;
  final LivenessStep currentStep;
  final double progress; // 0.0 to 1.0

  FaceOvalPainter({
    required this.borderColor,
    required this.currentStep,
    this.progress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final ovalWidth = size.width * 0.72;
    final ovalHeight = ovalWidth * 1.35;
    final ovalCenter = Offset(size.width / 2, size.height / 2 - 40);

    final ovalRect = Rect.fromCenter(
      center: ovalCenter,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Create path with cut-out hole for face oval
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // Border paint
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawOval(ovalRect, borderPaint);

    // Outer progress arc around oval
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6.0;

      final progressRect = Rect.fromCenter(
        center: ovalCenter,
        width: ovalWidth + 12,
        height: ovalHeight + 12,
      );

      final sweepAngle = 2 * 3.141592653589793 * progress;
      canvas.drawArc(progressRect, -3.141592653589793 / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceOvalPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.currentStep != currentStep ||
        oldDelegate.progress != progress;
  }
}
