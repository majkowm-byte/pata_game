import 'dart:math' show sin, cos, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MysteryBox extends PositionComponent {
  bool collected = false;
  double _bobPhase = 0;
  double _glowPhase = 0;
  double _rotatePhase = 0;
  double _vy = 0;
  bool _landed = false;
  late double _startY;

  final int scaleDirection;

  MysteryBox({required Vector2 pos, required this.scaleDirection}) {
    position = pos;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(32, 32);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (collected) return;

    if (!_landed) {
      _vy += 600 * dt;
      position.y += _vy * dt;
      if (position.y >= 470) {
        position.y = 470;
        _landed = true;
        _startY = position.y;
      }
      return;
    }

    _bobPhase += dt * 3;
    _glowPhase += dt * 4;
    _rotatePhase += dt * 2;
    position.y = _startY + sin(_bobPhase) * 4;
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
    final glowRadius = 22 + sin(_glowPhase) * 5;
    final glowOpacity = 0.2 + sin(_glowPhase) * 0.1;

    canvas.drawCircle(
      Offset(cx, cy),
      glowRadius,
      Paint()..color = Colors.white.withOpacity(glowOpacity),
    );

    for (int i = 0; i < 6; i++) {
      final angle = _rotatePhase + i * pi / 3;
      final px = cx + cos(angle) * 20;
      final py = cy + sin(angle) * 20;
      canvas.drawCircle(
        Offset(px, py),
        2,
        Paint()..color = Colors.white.withOpacity(0.5),
      );
    }

    canvas.save();
    canvas.translate(cx, cy);
    final tilt = sin(_bobPhase * 0.7) * 0.04;
    canvas.rotate(tilt);

    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-14, -14, 28, 28),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawLine(
      const Offset(-10, -10),
      const Offset(-5, -10),
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: Color(0xFF333333),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

    canvas.restore();
  }
}
