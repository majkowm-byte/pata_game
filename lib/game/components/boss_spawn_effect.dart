import 'dart:math' show Random, sin, cos, pi;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BossSpawnEffect extends PositionComponent {
  static final _rng = Random();

  final List<_SpawnParticle> _particles = [];
  final List<_SpawnRing> _rings = [];
  final List<_SpawnFlare> _flares = [];
  double _elapsed = 0;

  static const _duration = 2.5;

  BossSpawnEffect({required Vector2 pos}) {
    position = pos;
    size = Vector2.all(1);
  }

  @override
  Future<void> onLoad() async {
    // Burst particles — lots of them
    for (int i = 0; i < 60; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 80 + _rng.nextDouble() * 250;
      _particles.add(_SpawnParticle(
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 40,
        size: 3 + _rng.nextDouble() * 6,
        color: _randomColor(),
        maxLife: 0.8 + _rng.nextDouble() * 1.2,
      ));
    }

    // Upward spark fountain
    for (int i = 0; i < 30; i++) {
      _particles.add(_SpawnParticle(
        vx: (_rng.nextDouble() - 0.5) * 120,
        vy: -150 - _rng.nextDouble() * 200,
        size: 2 + _rng.nextDouble() * 4,
        color: _randomColor(),
        maxLife: 1.0 + _rng.nextDouble() * 1.0,
      ));
    }

    // Expanding shockwave rings
    for (int i = 0; i < 5; i++) {
      _rings.add(_SpawnRing(
        delay: i * 0.15,
        speed: 150 + i * 40.0,
        color: [
          const Color(0xFFFF4500),
          const Color(0xFFFFCC00),
          Colors.white,
          const Color(0xFFFF6600),
          const Color(0xFFFF2200),
        ][i],
        strokeWidth: 4.0 - i * 0.5,
      ));
    }

    // Radial flare lines
    for (int i = 0; i < 12; i++) {
      final angle = i * pi / 6 + _rng.nextDouble() * 0.3;
      _flares.add(_SpawnFlare(
        angle: angle,
        length: 80 + _rng.nextDouble() * 120,
        speed: 200 + _rng.nextDouble() * 150,
        width: 2 + _rng.nextDouble() * 3,
        color: _randomBrightColor(),
        maxLife: 0.5 + _rng.nextDouble() * 0.6,
      ));
    }
  }

  Color _randomColor() {
    const colors = [
      Color(0xFFFF4500),
      Color(0xFFFF6600),
      Color(0xFFFFCC00),
      Color(0xFFFFFF80),
      Color(0xFFFF2200),
      Colors.white,
      Color(0xFFFF8C00),
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  Color _randomBrightColor() {
    const colors = [
      Color(0xFFFFFF00),
      Color(0xFFFFCC00),
      Colors.white,
      Color(0xFFFF8C00),
      Color(0xFFFF4500),
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed > _duration) {
      removeFromParent();
      return;
    }

    for (final p in _particles) {
      p.life += dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 80 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    // Central flash (big and bright initially)
    final flashProgress = (_elapsed / 0.4).clamp(0.0, 1.0);
    if (flashProgress < 1.0) {
      final flashR = 30 + flashProgress * 80;
      final flashOp = (1.0 - flashProgress) * 0.9;
      canvas.drawCircle(
        Offset.zero,
        flashR,
        Paint()..color = Colors.white.withOpacity(flashOp),
      );
      canvas.drawCircle(
        Offset.zero,
        flashR * 0.6,
        Paint()..color = const Color(0xFFFFCC00).withOpacity(flashOp),
      );
    }

    // Expanding rings
    for (final ring in _rings) {
      final t = _elapsed - ring.delay;
      if (t < 0) continue;
      final ringProgress = (t / 1.5).clamp(0.0, 1.0);
      final radius = ringProgress * ring.speed;
      final opacity = (1.0 - ringProgress) * 0.7;
      if (opacity > 0.01) {
        canvas.drawCircle(
          Offset.zero,
          radius,
          Paint()
            ..color = ring.color.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring.strokeWidth * (1.0 - ringProgress * 0.5),
        );
      }
    }

    // Radial flare lines
    for (final f in _flares) {
      if (_elapsed > f.maxLife) continue;
      final progress = (_elapsed / f.maxLife).clamp(0.0, 1.0);
      final dist = progress * f.speed;
      final opacity = (1.0 - progress) * 0.8;
      final startDist = dist * 0.3;
      final endDist = dist;
      final sx = cos(f.angle) * startDist;
      final sy = sin(f.angle) * startDist;
      final ex = cos(f.angle) * endDist;
      final ey = sin(f.angle) * endDist;
      canvas.drawLine(
        Offset(sx, sy),
        Offset(ex, ey),
        Paint()
          ..color = f.color.withOpacity(opacity)
          ..strokeWidth = f.width * (1.0 - progress * 0.5)
          ..strokeCap = StrokeCap.round,
      );
    }

    // Particles
    for (final p in _particles) {
      if (p.life > p.maxLife) continue;
      final progress = p.life / p.maxLife;
      final opacity = (1.0 - progress) * 0.9;
      final s = p.size * (1.0 - progress * 0.4);
      canvas.drawCircle(
        Offset(p.x, p.y),
        s,
        Paint()..color = p.color.withOpacity(opacity),
      );
      // Glow around each particle
      if (s > 3) {
        canvas.drawCircle(
          Offset(p.x, p.y),
          s * 2,
          Paint()..color = p.color.withOpacity(opacity * 0.15),
        );
      }
    }
  }
}

class _SpawnParticle {
  double x = 0, y = 0;
  final double vx;
  double vy;
  double size;
  final Color color;
  double life = 0;
  final double maxLife;

  _SpawnParticle({
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.maxLife,
  });
}

class _SpawnRing {
  final double delay;
  final double speed;
  final Color color;
  final double strokeWidth;

  _SpawnRing({
    required this.delay,
    required this.speed,
    required this.color,
    required this.strokeWidth,
  });
}

class _SpawnFlare {
  final double angle;
  final double length;
  final double speed;
  final double width;
  final Color color;
  final double maxLife;

  _SpawnFlare({
    required this.angle,
    required this.length,
    required this.speed,
    required this.width,
    required this.color,
    required this.maxLife,
  });
}
