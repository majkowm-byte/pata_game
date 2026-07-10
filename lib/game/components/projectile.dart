import 'dart:math' show sin, cos, pi;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'boss.dart';
import 'enemy.dart';
import 'particle_effect.dart';
import '../audio/retro_sfx.dart';

class Projectile extends PositionComponent with CollisionCallbacks, HasGameRef {
  final double direction;
  final int damage;
  final double verticalSpeed;
  double _lifetime = 0;
  double _rotation = 0;
  double _trailTimer = 0;

  Projectile({
    required Vector2 startPos,
    required this.direction,
    this.damage = 1,
    this.verticalSpeed = 0,
  }) {
    position = startPos;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(16, 10);
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += direction * 350 * dt;
    position.y += verticalSpeed * dt;
    _lifetime += dt;
    _rotation += dt * 12 * direction;

    // Smoke trail
    _trailTimer += dt;
    if (_trailTimer > 0.08) {
      _trailTimer = 0;
      gameRef.world.add(_SmokeParticle(pos: Vector2(position.x, position.y + 5)));
    }

    if (_lifetime > 2) removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is Enemy && !other.isDead) {
      other.hit(damage);
      RetroSfx.instance.hit();
      gameRef.world.add(CollectEffect(pos: position + size / 2, color: Colors.orange));
      removeFromParent();
    } else if (other is Boss && !other.isDead) {
      other.hit(damage);
      RetroSfx.instance.hit();
      gameRef.world.add(CollectEffect(pos: position + size / 2, color: Colors.red));
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotation);

    // Sausage body
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
      const Radius.circular(5),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF8B4513));
    // Highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-size.x / 2 + 2, -size.y / 2 + 1, size.x - 4, size.y * 0.35),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFA0522D),
    );
    // Grill marks
    final markPaint = Paint()..color = const Color(0xFF654321)..strokeWidth = 1;
    canvas.drawLine(const Offset(-3, -4), const Offset(-3, 4), markPaint);
    canvas.drawLine(const Offset(1, -4), const Offset(1, 4), markPaint);
    canvas.drawLine(const Offset(5, -4), const Offset(5, 4), markPaint);

    canvas.restore();
  }
}

class _SmokeParticle extends PositionComponent {
  double _life = 0;
  static const _maxLife = 0.3;

  _SmokeParticle({required Vector2 pos}) {
    position = pos;
    size = Vector2.all(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 10 * dt;
    if (_life > _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / _maxLife;
    final r = 2 + progress * 4;
    final opacity = (1.0 - progress) * 0.3;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = Colors.grey.withOpacity(opacity),
    );
  }
}
