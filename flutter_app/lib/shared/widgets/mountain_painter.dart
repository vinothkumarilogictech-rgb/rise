import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class MountainScenePainter extends CustomPainter {
  final double progressPercent; // 0.0 to 100.0
  final double animationValue; // 0.0 to 1.0
  final bool isFullScreen;

  MountainScenePainter({
    required this.progressPercent,
    this.animationValue = 1.0,
    this.isFullScreen = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Night Sky Background Gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF04060C), Color(0xFF0A1024), Color(0xFF131D38)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Stars
    final random = Random(42);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < (isFullScreen ? 60 : 35); i++) {
      final sx = random.nextDouble() * w;
      final sy = random.nextDouble() * (h * 0.65);
      final radius = 0.6 + random.nextDouble() * 1.4;
      final opacity = 0.2 + 0.6 * sin((animationValue * 2 * pi) + (i * 0.5)).abs();
      starPaint.color = Colors.white.withOpacity(opacity.clamp(0.1, 0.9));
      canvas.drawCircle(Offset(sx, sy), radius, starPaint);
    }

    // 3. Summit Glow Aura
    final summitGlowCenter = Offset(w * 0.72, h * (isFullScreen ? 0.18 : 0.22));
    final summitAuraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.cyanHighlight.withOpacity(0.35),
          AppColors.violetAccent.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: summitGlowCenter, radius: w * 0.35));
    canvas.drawCircle(summitGlowCenter, w * 0.35, summitAuraPaint);

    // 4. Distant Mountain Ridge (Deep Violet/Navy)
    final distantRidge = Path();
    distantRidge.moveTo(0, h * 0.65);
    distantRidge.lineTo(w * 0.2, h * 0.45);
    distantRidge.lineTo(w * 0.42, h * 0.52);
    distantRidge.lineTo(w * 0.72, h * (isFullScreen ? 0.18 : 0.22)); // Peak
    distantRidge.lineTo(w * 0.88, h * 0.42);
    distantRidge.lineTo(w, h * 0.55);
    distantRidge.lineTo(w, h);
    distantRidge.lineTo(0, h);
    distantRidge.close();

    final distantPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1B2344), Color(0xFF10172D)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(distantRidge, distantPaint);

    // 5. Midground Ridge (Rocky Navy)
    final midRidge = Path();
    midRidge.moveTo(0, h * 0.75);
    midRidge.lineTo(w * 0.28, h * 0.55);
    midRidge.lineTo(w * 0.52, h * 0.62);
    midRidge.lineTo(w * 0.75, h * 0.48);
    midRidge.lineTo(w, h * 0.7);
    midRidge.lineTo(w, h);
    midRidge.lineTo(0, h);
    midRidge.close();

    final midPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF121B35), Color(0xFF090E1F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(midRidge, midPaint);

    // 6. Foreground Ridge (Dark Base)
    final foreRidge = Path();
    foreRidge.moveTo(0, h * 0.85);
    foreRidge.lineTo(w * 0.35, h * 0.78);
    foreRidge.lineTo(w * 0.65, h * 0.82);
    foreRidge.lineTo(w, h * 0.88);
    foreRidge.lineTo(w, h);
    foreRidge.lineTo(0, h);
    foreRidge.close();

    final forePaint = Paint()..color = const Color(0xFF070B18);
    canvas.drawPath(foreRidge, forePaint);

    // 7. Mountain Trail Curve (Ascending path from base to summit)
    final trailStart = Offset(w * 0.12, h * 0.86);
    final p1 = Offset(w * 0.32, h * 0.74);
    final p2 = Offset(w * 0.24, h * 0.60);
    final p3 = Offset(w * 0.50, h * 0.48);
    final p4 = Offset(w * 0.42, h * 0.35);
    final trailEnd = summitGlowCenter;

    final trailPath = Path();
    trailPath.moveTo(trailStart.dx, trailStart.dy);
    trailPath.quadraticBezierTo(p1.dx, p1.dy, (p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    trailPath.quadraticBezierTo(p2.dx, p2.dy, p3.dx, p3.dy);
    trailPath.quadraticBezierTo(p4.dx, p4.dy, trailEnd.dx, trailEnd.dy);

    // Trail base glow
    final trailGlowPaint = Paint()
      ..color = AppColors.cyanHighlight.withOpacity(0.18)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trailPath, trailGlowPaint);

    // Trail dashed line
    final trailPaint = Paint()
      ..color = AppColors.cyanHighlight.withOpacity(0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trailPath, trailPaint);

    // 8. Milestones along path
    final pathMetrics = trailPath.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final totalLength = metric.length;

      // Draw milestone dots
      for (int i = 1; i <= 6; i++) {
        final nodeRatio = i / 6.0;
        final tangent = metric.getTangentForOffset(totalLength * nodeRatio);
        if (tangent != null) {
          final isUnlocked = (progressPercent / 100.0) >= nodeRatio;
          final nodePaint = Paint()
            ..color = isUnlocked ? AppColors.cyanHighlight : const Color(0xFF2E3E66);
          canvas.drawCircle(tangent.position, isUnlocked ? 3.5 : 2.5, nodePaint);

          if (isUnlocked) {
            final halo = Paint()
              ..color = AppColors.cyanHighlight.withOpacity(0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5;
            canvas.drawCircle(tangent.position, 6.0, halo);
          }
        }
      }

      // 9. Climber Current Position Marker
      final clampedProgress = (progressPercent / 100.0).clamp(0.02, 1.0);
      final currentOffset = metric.getTangentForOffset(totalLength * clampedProgress * animationValue);
      if (currentOffset != null) {
        final pos = currentOffset.position;

        // Pulsating outer aura
        final pulseRadius = 10.0 + 3.0 * sin(animationValue * 2 * pi);
        final beaconAuraPaint = Paint()
          ..color = AppColors.cyanHighlight.withOpacity(0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, pulseRadius, beaconAuraPaint);

        // Ring
        final beaconRingPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, 5.5, beaconRingPaint);

        // Core dot
        final beaconCorePaint = Paint()..color = AppColors.cyanHighlight;
        canvas.drawCircle(pos, 3.5, beaconCorePaint);
      }
    }

    // 10. Summit Beacon Star
    final summitPaint = Paint()..color = Colors.white;
    canvas.drawCircle(summitGlowCenter, 4.0, summitPaint);
    final summitCrossPaint = Paint()
      ..color = AppColors.cyanHighlight
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(summitGlowCenter.dx - 8, summitGlowCenter.dy),
      Offset(summitGlowCenter.dx + 8, summitGlowCenter.dy),
      summitCrossPaint,
    );
    canvas.drawLine(
      Offset(summitGlowCenter.dx, summitGlowCenter.dy - 8),
      Offset(summitGlowCenter.dx, summitGlowCenter.dy + 8),
      summitCrossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MountainScenePainter oldDelegate) {
    return oldDelegate.progressPercent != progressPercent ||
        oldDelegate.animationValue != animationValue;
  }
}
