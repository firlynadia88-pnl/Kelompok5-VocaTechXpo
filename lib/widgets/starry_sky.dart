
import 'dart:math';
import 'package:flutter/material.dart';

class Star {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final int seed;

  const Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.seed,
  });
}

class StarrySkyPainter extends CustomPainter {
  final double animationValue;
  final List<Star> stars;

  const StarrySkyPainter({
    required this.animationValue,
    required this.stars,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (final star in stars) {
      final currentY =
          (star.y + animationValue * star.speed) % 1.0;

      final opacity = (
        (sin(animationValue * 2 * pi + star.seed) + 1) / 2
      ).clamp(0.2, 1.0);

      paint.color = Colors.white.withValues(
        alpha: opacity * 0.9,
      );

      canvas.drawCircle(
        Offset(
          star.x * size.width,
          currentY * size.height,
        ),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarrySkyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.stars != stars;
  }
}
