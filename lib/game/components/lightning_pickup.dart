import 'dart:math' show cos, sin, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LightningPickup extends PositionComponent {
  bool collected = false;
  double _phase = 0;
  double _sparklePhase = 0;
  late double _startY;

  LightningPickup({required Vector2 pos}) {
    position = pos;
    _startY = pos.y;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(20, 24);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;
    _phase += dt * 5;
    _sparklePhase += dt * 8;
    position.y = _startY + sin(_phase * 0.8) * 4;
  }

  void collect() {
    collected = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;

    final cx = size.x / 2;
    final cy = size.y / 2;

    // Glow
    final glowOpacity = 0.2 + sin(_sparklePhase) * 0.1;
    canvas.drawCircle(
      Offset(cx, cy),
      14,
      Paint()..color = const Color(0xFF00BFFF).withOpacity(glowOpacity),
    );

    // Lightning bolt shape
    final bolt = Path()
      ..moveTo(cx + 2, 0)
      ..lineTo(cx - 4, cy + 2)
      ..lineTo(cx, cy)
      ..lineTo(cx - 2, size.y)
      ..lineTo(cx + 4, cy - 2)
      ..lineTo(cx, cy)
      ..close();

    canvas.drawPath(bolt, Paint()..color = const Color(0xFF00BFFF));
    canvas.drawPath(
      bolt,
      Paint()..color = Colors.white.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    // Sparkles
    for (int i = 0; i < 3; i++) {
      final angle = _sparklePhase + i * pi * 2 / 3;
      final dist = 12 + sin(_sparklePhase * 0.5 + i) * 3;
      final sx = cx + cos(angle) * dist;
      final sy = cy + sin(angle) * dist;
      canvas.drawCircle(
        Offset(sx, sy),
        1.2,
        Paint()..color = const Color(0xFF00BFFF).withOpacity(0.6),
      );
    }
  }
}
