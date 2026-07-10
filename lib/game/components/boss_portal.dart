import 'dart:math' show sin, cos, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BossPortal extends PositionComponent {
  double _phase = 0;
  double _spawnTimer = 0;

  BossPortal({required Vector2 pos}) {
    position = pos;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(60, 80);
    position.x -= size.x / 2;
    position.y -= size.y;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 3;
    _spawnTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_spawnTimer < 0.1) return;

    final cx = size.x / 2;
    final cy = size.y / 2;
    final fadeIn = (_spawnTimer / 1.0).clamp(0.0, 1.0);

    // Outer glow
    for (int i = 3; i >= 0; i--) {
      final r = 25.0 + i * 8;
      final opacity = fadeIn * (0.08 + sin(_phase + i) * 0.04);
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = Color.fromRGBO(100, 0, 255, opacity.clamp(0.0, 0.3)),
      );
    }

    // Portal oval
    final portalPaint = Paint()
      ..color = Color.fromRGBO(120, 0, 255, 0.6 * fadeIn)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 40, height: 65),
      portalPaint,
    );

    // Inner bright core
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 25, height: 45),
      Paint()..color = Color.fromRGBO(200, 150, 255, 0.7 * fadeIn),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 25),
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * fadeIn),
    );

    // Swirling particles
    for (int i = 0; i < 8; i++) {
      final angle = _phase * 2 + i * pi / 4;
      final radius = 18.0 + sin(_phase + i * 1.5) * 6;
      final px = cx + cos(angle) * radius * 0.6;
      final py = cy + sin(angle) * radius;
      final sparkleSize = 2.0 + sin(_phase * 3 + i) * 1;
      canvas.drawCircle(
        Offset(px, py),
        sparkleSize,
        Paint()..color = Color.fromRGBO(200, 150, 255, 0.7 * fadeIn),
      );
    }

    // Top/bottom edges glow
    final edgePaint = Paint()
      ..color = Color.fromRGBO(150, 50, 255, 0.5 * fadeIn)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 44, height: 70),
      edgePaint,
    );
  }
}
