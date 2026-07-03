import 'dart:math' show sin, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FinishFlag extends PositionComponent {
  double _wavePhase = 0;
  double _sparklePhase = 0;

  FinishFlag({required Vector2 pos}) {
    position = pos;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(40, 80);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _wavePhase += dt * 4;
    _sparklePhase += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    final poleX = size.x / 2;

    // Pole shadow
    canvas.drawRect(
      Rect.fromLTWH(poleX, 0, 5, size.y),
      Paint()..color = Colors.black.withOpacity(0.1),
    );

    // Pole
    canvas.drawRect(
      Rect.fromLTWH(poleX - 2, 0, 4, size.y),
      Paint()..color = Colors.grey.shade300,
    );
    // Pole highlight
    canvas.drawRect(
      Rect.fromLTWH(poleX - 2, 0, 1.5, size.y),
      Paint()..color = Colors.white.withOpacity(0.3),
    );

    // Waving flag
    final flagPath = Path();
    flagPath.moveTo(poleX + 2, 4);

    for (double x = 0; x <= 20; x += 2) {
      final wave = sin(_wavePhase + x * 0.3) * 3;
      flagPath.lineTo(poleX + 2 + x, 4 + wave);
    }
    for (double x = 20; x >= 0; x -= 2) {
      final wave = sin(_wavePhase + x * 0.3) * 3;
      flagPath.lineTo(poleX + 2 + x, 24 + wave);
    }
    flagPath.close();

    // Flag gradient effect
    canvas.drawPath(flagPath, Paint()..color = Colors.red);
    // Flag stripe
    final stripePath = Path();
    stripePath.moveTo(poleX + 2, 12);
    for (double x = 0; x <= 20; x += 2) {
      final wave = sin(_wavePhase + x * 0.3) * 3;
      stripePath.lineTo(poleX + 2 + x, 12 + wave);
    }
    canvas.drawPath(
      stripePath,
      Paint()..color = Colors.white.withOpacity(0.4)..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // Ball on top
    canvas.drawCircle(
      Offset(poleX, 2),
      3,
      Paint()..color = Colors.amber,
    );
    canvas.drawCircle(
      Offset(poleX - 0.5, 1),
      1,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    // Base
    final basePath = Path()
      ..moveTo(poleX - 12, size.y)
      ..lineTo(poleX + 12, size.y)
      ..lineTo(poleX + 8, size.y - 8)
      ..lineTo(poleX - 8, size.y - 8)
      ..close();
    canvas.drawPath(basePath, Paint()..color = Colors.grey.shade500);
    canvas.drawPath(
      basePath,
      Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    // Sparkles around flag
    for (int i = 0; i < 5; i++) {
      final sparkleY = 5 + i * 15.0;
      final sparkleX = poleX + 25 + sin(_sparklePhase + i * 1.2) * 8;
      final opacity = (sin(_sparklePhase * 2 + i) * 0.5 + 0.5).clamp(0.0, 0.8);
      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        1.5,
        Paint()..color = Colors.yellow.withOpacity(opacity),
      );
    }
  }
}
