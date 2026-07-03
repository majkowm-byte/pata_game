import 'dart:math' show sin, cos, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Enemy extends PositionComponent with CollisionCallbacks {
  final int damage;
  final int hp;
  final double patrolSpeed;
  final double patrolRange;

  int _currentHp = 0;
  bool isDead = false;
  double _startX = 0;
  double _direction = 1;
  double _deathTimer = 0;

  double _bobPhase = 0;
  double _runPhase = 0;
  double _hitFlashTimer = 0;
  double _angryPulse = 0;
  double _squash = 1.0;

  Enemy({
    required Vector2 pos,
    this.damage = 1,
    this.hp = 1,
    this.patrolSpeed = 60,
    this.patrolRange = 100,
  }) {
    position = pos;
    _startX = pos.x;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(36, 36);
    _currentHp = hp;
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      _deathTimer += dt;
      _squash += (3.0 - _squash) * 6 * dt;
      if (_deathTimer > 0.6) removeFromParent();
      return;
    }

    _bobPhase += dt * 5;
    _runPhase += dt * 8;
    _angryPulse += dt * 3;
    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;

    position.x += patrolSpeed * _direction * dt;

    if ((position.x - _startX).abs() > patrolRange) {
      _direction *= -1;
    }

    _squash += (1.0 - _squash) * 10 * dt;
  }

  void stomp() {
    _currentHp--;
    _squash = 0.5;
    _hitFlashTimer = 0.15;
    if (_currentHp <= 0) isDead = true;
  }

  void hit(int damage) {
    _currentHp -= damage;
    _hitFlashTimer = 0.15;
    _squash = 0.7;
    if (_currentHp <= 0) isDead = true;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    if (isDead) {
      final deathProgress = (_deathTimer / 0.6).clamp(0.0, 1.0);
      final opacity = 1.0 - deathProgress;
      canvas.save();
      canvas.translate(cx, size.y);
      canvas.scale(1.0 + deathProgress * 0.5, 1.0 - deathProgress * 0.8);
      canvas.translate(-cx, -size.y);

      canvas.drawCircle(
        Offset(cx, cy),
        16,
        Paint()..color = const Color(0xFF8B0000).withOpacity(opacity),
      );
      // X eyes
      final xPaint = Paint()..color = Colors.white.withOpacity(opacity)..strokeWidth = 2..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx - 5, cy - 3), Offset(cx - 1, cy + 1), xPaint);
      canvas.drawLine(Offset(cx - 5, cy + 1), Offset(cx - 1, cy - 3), xPaint);
      canvas.drawLine(Offset(cx + 1, cy - 3), Offset(cx + 5, cy + 1), xPaint);
      canvas.drawLine(Offset(cx + 1, cy + 1), Offset(cx + 5, cy - 3), xPaint);

      // Stars above head
      for (int i = 0; i < 3; i++) {
        final angle = deathProgress * pi * 2 + i * pi * 2 / 3;
        final starX = cx + cos(angle) * 14;
        final starY = cy - 18 + sin(angle) * 4;
        canvas.drawCircle(Offset(starX, starY), 2, Paint()..color = Colors.yellow.withOpacity(opacity));
      }

      canvas.restore();
      return;
    }

    final isFlashing = _hitFlashTimer > 0;
    final bob = sin(_bobPhase) * 2;
    final pulse = 1.0 + sin(_angryPulse) * 0.03;

    canvas.save();
    canvas.translate(cx, size.y);
    canvas.scale(1.0 / _squash, _squash);
    canvas.translate(-cx, -size.y);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.y + 2), width: 28, height: 6),
      Paint()..color = Colors.black.withOpacity(0.15),
    );

    // Animated legs
    final legSwing = sin(_runPhase) * 5;
    final legPaint = Paint()..color = const Color(0xFF8B0000)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 6, cy + 14 + bob),
      Offset(cx - 8 + legSwing, size.y),
      legPaint,
    );
    canvas.drawLine(
      Offset(cx + 6, cy + 14 + bob),
      Offset(cx + 8 - legSwing, size.y),
      legPaint,
    );

    // Body
    final bodyColor = isFlashing ? Colors.white : const Color(0xFF8B0000);
    canvas.drawCircle(
      Offset(cx, cy + bob),
      16 * pulse,
      Paint()..color = bodyColor,
    );

    // Eye
    canvas.drawCircle(Offset(cx, cy - 1 + bob), 8, Paint()..color = Colors.yellow);
    canvas.drawCircle(
      Offset(cx + _direction * 3, cy - 1 + bob),
      4,
      Paint()..color = Colors.black,
    );
    // Angry eyebrow
    final browPaint = Paint()..color = const Color(0xFF5a0000)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 7, cy - 9 + bob),
      Offset(cx, cy - 6 + bob),
      browPaint,
    );
    canvas.drawLine(
      Offset(cx + 7, cy - 9 + bob),
      Offset(cx, cy - 6 + bob),
      browPaint,
    );

    // Horns with slight wobble
    final hornWobble = sin(_bobPhase * 1.3) * 1.5;
    final hornPaint = Paint()..color = const Color(0xFFAA2222)..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 8, cy - 14 + bob),
      Offset(cx - 12 + hornWobble, cy - 24 + bob),
      hornPaint,
    );
    canvas.drawLine(
      Offset(cx + 8, cy - 14 + bob),
      Offset(cx + 12 - hornWobble, cy - 24 + bob),
      hornPaint,
    );

    canvas.restore();
  }
}
