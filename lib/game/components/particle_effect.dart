import 'dart:math' show Random, cos, sin, pi;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ParticleEffect extends PositionComponent {
  final Color color;
  final int count;
  final double spread;
  final double lifetime;

  final List<_Particle> _particles = [];
  double _elapsed = 0;
  static final _rng = Random();

  ParticleEffect({
    required Vector2 pos,
    this.color = Colors.white,
    this.count = 8,
    this.spread = 40,
    this.lifetime = 0.5,
  }) {
    position = pos;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2.all(1);
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 30 + _rng.nextDouble() * spread;
      _particles.add(_Particle(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 20,
        size: 2 + _rng.nextDouble() * 3,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed > lifetime) {
      removeFromParent();
      return;
    }
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 60 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / lifetime).clamp(0.0, 1.0);
    final opacity = 1.0 - progress;

    for (final p in _particles) {
      final s = p.size * (1.0 - progress * 0.5);
      canvas.drawCircle(
        Offset(p.x, p.y),
        s,
        Paint()..color = color.withOpacity(opacity),
      );
    }
  }
}

class _Particle {
  double x = 0;
  double y = 0;
  double vx;
  double vy;
  double size;

  _Particle({required this.vx, required this.vy, required this.size});
}

class DustEffect extends ParticleEffect {
  DustEffect({required Vector2 pos})
      : super(
          pos: pos,
          color: const Color(0xFF8B7355),
          count: 6,
          spread: 30,
          lifetime: 0.4,
        );
}

class CollectEffect extends ParticleEffect {
  CollectEffect({required Vector2 pos, required Color color})
      : super(
          pos: pos,
          color: color,
          count: 10,
          spread: 50,
          lifetime: 0.5,
        );
}

class StompEffect extends ParticleEffect {
  StompEffect({required Vector2 pos})
      : super(
          pos: pos,
          color: Colors.yellow,
          count: 12,
          spread: 60,
          lifetime: 0.4,
        );
}
