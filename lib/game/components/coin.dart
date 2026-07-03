import 'dart:math' show cos, sin, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Coin extends PositionComponent {
  bool collected = false;
  double _phase = 0;
  double _sparklePhase = 0;
  late double _startY;

  Coin({required Vector2 pos}) {
    position = pos;
    _startY = pos.y;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(20, 20);
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;
    _phase += dt * 4;
    _sparklePhase += dt * 6;
    position.y = _startY + sin(_phase * 0.8) * 3;
  }

  void collect() {
    collected = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;

    final scaleX = cos(_phase).abs().clamp(0.3, 1.0);
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scaleX, 1.0);

    // Outer glow
    canvas.drawCircle(
      Offset.zero,
      12,
      Paint()..color = const Color(0xFFFFD700).withOpacity(0.15),
    );

    // Coin body
    canvas.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFFFFD700));
    // Highlight
    canvas.drawArc(
      const Rect.fromLTWH(-9, -9, 18, 18),
      -pi * 0.8,
      pi * 0.6,
      false,
      Paint()..color = const Color(0xFFFFE44D)..style = PaintingStyle.stroke..strokeWidth = 2,
    );
    // Border
    canvas.drawCircle(Offset.zero, 9, Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    // Inner circle
    canvas.drawCircle(Offset.zero, 4.5, Paint()..color = const Color(0xFFDAA520));
    canvas.drawCircle(Offset.zero, 4.5, Paint()..color = const Color(0xFFB8860B)..style = PaintingStyle.stroke..strokeWidth = 0.8);

    canvas.restore();

    // Sparkles
    for (int i = 0; i < 3; i++) {
      final angle = _sparklePhase + i * pi * 2 / 3;
      final dist = 11 + sin(_sparklePhase * 0.7 + i) * 3;
      final sx = size.x / 2 + cos(angle) * dist;
      final sy = size.y / 2 + sin(angle) * dist;
      final sparkleSize = (1.5 + sin(_sparklePhase * 2 + i * 1.5) * 1.0).clamp(0.5, 2.5);
      canvas.drawCircle(
        Offset(sx, sy),
        sparkleSize,
        Paint()..color = Colors.white.withOpacity(0.7),
      );
    }
  }
}
