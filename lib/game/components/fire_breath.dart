import 'dart:math' show sin;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player.dart';

class FireBreath extends PositionComponent with CollisionCallbacks {
  final double direction;
  final double _spawnDelay;
  double _lifetime = 0;
  double _trailTimer = 0;
  bool _hitPlayer = false;
  bool _active = false;

  FireBreath({required Vector2 startPos, required this.direction, double delay = 0})
      : _spawnDelay = delay {
    position = startPos;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(28, 28);
    add(RectangleHitbox(isSolid: true));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_active) {
      if (_spawnDelay > 0) _lifetime += dt;
      if (_lifetime >= _spawnDelay) {
        _active = true;
        _lifetime = 0;
      }
      return;
    }
    position.x += direction * 220 * dt;
    position.y += sin(_lifetime * 6) * 15 * dt;
    _lifetime += dt;

    _trailTimer += dt;
    if (_trailTimer > 0.05) {
      _trailTimer = 0;
      parent?.add(_FireParticle(pos: position + size / 2));
    }

    if (_lifetime > 1.5) removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (!_hitPlayer && _active && other is Player) {
      _hitPlayer = true;
      other.takeDamage(1);
      other.applyBurn(2.5);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;
    final progress = (_lifetime / 1.5).clamp(0.0, 1.0);
    final r = 7.0 + progress * 7;
    final glow = 1.0 - progress * 0.3;
    final center = Offset(size.x / 2, size.y / 2);

    canvas.drawCircle(center, r + 4, Paint()..color = Colors.red.withOpacity(0.15 * glow));
    canvas.drawCircle(center, r, Paint()..color = Color.lerp(const Color(0xFFFF4500), const Color(0xFFFF8C00), progress)!.withOpacity(glow));
    canvas.drawCircle(center, r * 0.45, Paint()..color = Colors.yellow.withOpacity(0.8 * glow));
  }
}

class _FireParticle extends PositionComponent {
  double _life = 0;
  static const _maxLife = 0.3;

  _FireParticle({required Vector2 pos}) {
    position = pos;
    size = Vector2.all(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 18 * dt;
    if (_life > _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / _maxLife;
    final r = 3 + progress * 5;
    final opacity = (1.0 - progress) * 0.45;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = Color.lerp(Colors.orange, Colors.red.withOpacity(0), progress)!.withOpacity(opacity),
    );
  }
}
