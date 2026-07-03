import 'dart:math' show sin, cos, pi;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Background extends PositionComponent with HasGameRef {
  double _cloudPhase = 0;
  double _grassPhase = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(5000, 600);
    priority = -10;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cloudPhase += dt * 8;
    _grassPhase += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    // Sky gradient
    final skyRect = Rect.fromLTWH(0, 0, size.x, size.y * 0.7);
    canvas.drawRect(
      skyRect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5BA3D9), Color(0xFF87CEEB), Color(0xFFB0E0E6)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(skyRect),
    );

    // Sun
    canvas.drawCircle(
      const Offset(200, 80),
      40,
      Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.3),
    );
    canvas.drawCircle(
      const Offset(200, 80),
      25,
      Paint()..color = const Color(0xFFFFEB3B).withOpacity(0.5),
    );
    canvas.drawCircle(
      const Offset(200, 80),
      15,
      Paint()..color = const Color(0xFFFFD54F),
    );

    // Clouds — drifting
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.6);
    final cloudPaint2 = Paint()..color = Colors.white.withOpacity(0.75);
    for (int i = 0; i < 12; i++) {
      final baseX = 100 + i * 420.0;
      final drift = sin(_cloudPhase * 0.02 + i * 0.8) * 15;
      final y = 40 + (i % 3) * 30.0 + sin(i * 1.5) * 20;
      final w = 80 + (i % 4) * 25.0;
      canvas.drawOval(Rect.fromCenter(center: Offset(baseX + drift, y), width: w, height: 25), cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(baseX + drift + w * 0.25, y - 8), width: w * 0.6, height: 18), cloudPaint2);
    }

    // Far mountains
    final mountainPaint = Paint()..color = const Color(0xFF7BA893).withOpacity(0.4);
    for (double x = 0; x < size.x; x += 200) {
      final h = 60 + sin(x * 0.01) * 30;
      final path = Path()
        ..moveTo(x - 20, size.y * 0.68)
        ..lineTo(x + 100, size.y * 0.68 - h)
        ..lineTo(x + 220, size.y * 0.68)
        ..close();
      canvas.drawPath(path, mountainPaint);
    }

    // Near hills
    final hillPaint = Paint()..color = const Color(0xFF90C695);
    final hillPaint2 = Paint()..color = const Color(0xFF7DB87F);
    for (double x = 0; x < size.x; x += 250) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 125, size.y * 0.7), width: 300, height: 100),
        hillPaint,
      );
    }
    for (double x = 120; x < size.x; x += 350) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 175, size.y * 0.72), width: 250, height: 80),
        hillPaint2,
      );
    }

    // Ground
    final groundRect = Rect.fromLTWH(0, size.y * 0.68, size.x, size.y * 0.32);
    canvas.drawRect(
      groundRect,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5a9e30), Color(0xFF3d7a1a), Color(0xFF2d5a10)],
      ).createShader(groundRect),
    );

    // Grass tufts
    final grassPaint = Paint()..color = const Color(0xFF6abf3b)..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.x; x += 18) {
      final baseY = size.y * 0.68;
      final sway = sin(_grassPhase + x * 0.15) * 2;
      final h = 5 + (x.toInt() % 7) * 1.5;
      canvas.drawLine(Offset(x, baseY), Offset(x + sway, baseY - h), grassPaint);
      canvas.drawLine(Offset(x + 4, baseY), Offset(x + 4 + sway * 0.8, baseY - h * 0.7), grassPaint);
    }

    // Small flowers
    final flowerColors = [Colors.red, Colors.yellow, Colors.pink, Colors.white];
    for (double x = 50; x < size.x; x += 120) {
      final color = flowerColors[(x.toInt() ~/ 120) % flowerColors.length];
      final baseY = size.y * 0.68 - 2;
      final sway = sin(_grassPhase * 0.8 + x * 0.1) * 1.5;
      // Stem
      canvas.drawLine(
        Offset(x, baseY + 4),
        Offset(x + sway, baseY - 6),
        Paint()..color = const Color(0xFF4a8a20)..strokeWidth = 1,
      );
      // Petals
      canvas.drawCircle(Offset(x + sway, baseY - 7), 3, Paint()..color = color);
      canvas.drawCircle(Offset(x + sway, baseY - 7), 1.5, Paint()..color = Colors.yellow);
    }
  }
}
