import 'dart:math' show sin;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlatformBlock extends PositionComponent with HasGameRef {
  final Color color;
  double _grassPhase = 0;

  PlatformBlock({
    required Vector2 pos,
    required Vector2 blockSize,
    this.color = const Color(0xFF4a7a25),
  }) {
    position = pos;
    size = blockSize;
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _grassPhase += dt * 2.5;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Main body gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color, Color.lerp(color, Colors.black, 0.3)!],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Dirt texture — brick pattern
    final linePaint = Paint()..color = Colors.black.withOpacity(0.08)..strokeWidth = 0.5;
    for (double y = 8; y < size.y; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), linePaint);
      final offset = (y ~/ 16) % 2 == 0 ? 0.0 : 16.0;
      for (double x = offset; x < size.x; x += 32) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 16), linePaint);
      }
    }

    // Top grass strip
    final grassGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF7CCD3B), const Color(0xFF5aA825)],
    );
    final grassRect = Rect.fromLTWH(0, 0, size.x, 6);
    canvas.drawRect(grassRect, Paint()..shader = grassGradient.createShader(grassRect));

    // Grass blades on top
    final bladePaint = Paint()..color = const Color(0xFF8AE040)..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    for (double x = 2; x < size.x; x += 6) {
      final sway = sin(_grassPhase + x * 0.2) * 1.5;
      final h = 3 + (x.toInt() % 5) * 0.8;
      canvas.drawLine(Offset(x, 0), Offset(x + sway, -h), bladePaint);
    }

    // Edge highlight
    canvas.drawLine(
      Offset.zero,
      Offset(size.x, 0),
      Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1,
    );
  }
}
