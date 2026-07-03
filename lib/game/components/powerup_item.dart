import 'dart:math' show sin, cos, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/powerup_type.dart';

class PowerUpItem extends PositionComponent {
  final PowerUpType type;
  bool collected = false;
  double _bobPhase = 0;
  double _glowPhase = 0;
  double _rotatePhase = 0;
  late double _startY;

  PowerUpItem({required Vector2 pos, required this.type}) {
    position = pos;
    _startY = pos.y;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(28, 28);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;
    _bobPhase += dt * 3;
    _glowPhase += dt * 4;
    _rotatePhase += dt * 2;
    position.y = _startY + sin(_bobPhase) * 5;
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
    final glowRadius = 18 + sin(_glowPhase) * 4;
    final glowOpacity = 0.15 + sin(_glowPhase) * 0.1;

    // Pulsating outer glow
    canvas.drawCircle(
      Offset(cx, cy),
      glowRadius,
      Paint()..color = type.color.withOpacity(glowOpacity),
    );

    // Rotating particles
    for (int i = 0; i < 4; i++) {
      final angle = _rotatePhase + i * pi / 2;
      final px = cx + cos(angle) * 16;
      final py = cy + sin(angle) * 16;
      canvas.drawCircle(
        Offset(px, py),
        1.5,
        Paint()..color = type.color.withOpacity(0.5),
      );
    }

    // Box with slight rotation
    canvas.save();
    canvas.translate(cx, cy);
    final tilt = sin(_bobPhase * 0.7) * 0.05;
    canvas.rotate(tilt);

    // Box shadow
    final shadowRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-10, -9, 20, 20),
      const Radius.circular(5),
    );
    canvas.drawRRect(shadowRect, Paint()..color = Colors.black.withOpacity(0.1));

    // Box body
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-11, -11, 22, 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(rect, Paint()..color = type.color);
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    // Highlight stripe
    canvas.drawLine(
      const Offset(-8, -8),
      const Offset(-4, -8),
      Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = 2..strokeCap = StrokeCap.round,
    );

    // "?" with bob
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    canvas.restore();
  }
}
