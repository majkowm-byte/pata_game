import 'dart:math' show Random, sin, cos, pi;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FireWall extends PositionComponent {
  static final _rng = Random();

  final List<_Flame> _flames = [];
  final List<_Ember> _embers = [];
  double _phase = _rng.nextDouble() * 10;

  FireWall({required Vector2 pos, required double wallHeight}) {
    position = pos;
    size = Vector2(24, wallHeight);
  }

  @override
  Future<void> onLoad() async {
    for (int i = 0; i < 18; i++) {
      _flames.add(_Flame(
        baseY: size.y * (i / 18),
        speed: 1.5 + _rng.nextDouble() * 2.0,
        amplitude: 3.0 + _rng.nextDouble() * 5.0,
        offset: _rng.nextDouble() * pi * 2,
        baseSize: 8.0 + _rng.nextDouble() * 8.0,
      ));
    }
    for (int i = 0; i < 10; i++) {
      _embers.add(_Ember.spawn(size));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt;
    for (final e in _embers) {
      e.life += dt;
      e.x += e.vx * dt;
      e.y -= e.vy * dt;
      if (e.life > e.maxLife) {
        e.reset(size);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;

    // Core glow column
    final coreGrad = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        const Color(0xFFFF4500).withOpacity(0.3),
        const Color(0xFFFF6600).withOpacity(0.5),
        const Color(0xFFFF4500).withOpacity(0.3),
        Colors.transparent,
      ],
    );
    final coreRect = Rect.fromLTWH(-4, 0, size.x + 8, size.y);
    canvas.drawRect(coreRect, Paint()..shader = coreGrad.createShader(coreRect));

    // Flame tongues
    for (final f in _flames) {
      final sway = sin(_phase * f.speed + f.offset) * f.amplitude;
      final flicker = 0.6 + sin(_phase * f.speed * 2.3 + f.offset) * 0.4;
      final fx = cx + sway;
      final fy = f.baseY;
      final r = f.baseSize * flicker;

      // Outer orange glow
      canvas.drawCircle(
        Offset(fx, fy),
        r * 1.4,
        Paint()..color = const Color(0xFFFF4500).withOpacity(0.15 * flicker),
      );
      // Mid flame
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, fy), width: r * 0.8, height: r * 1.5),
        Paint()..color = Color.lerp(
          const Color(0xFFFF6600),
          const Color(0xFFFFCC00),
          sin(_phase * f.speed * 1.7 + f.offset) * 0.5 + 0.5,
        )!.withOpacity(0.6 * flicker),
      );
      // Inner bright core
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fx, fy), width: r * 0.3, height: r * 0.8),
        Paint()..color = const Color(0xFFFFFF80).withOpacity(0.7 * flicker),
      );
    }

    // Rising embers
    for (final e in _embers) {
      final progress = e.life / e.maxLife;
      final opacity = (1.0 - progress) * 0.8;
      final s = e.size * (1.0 - progress * 0.5);
      canvas.drawCircle(
        Offset(e.x, e.y),
        s,
        Paint()..color = Color.lerp(
          const Color(0xFFFFCC00),
          const Color(0xFFFF2200),
          progress,
        )!.withOpacity(opacity),
      );
    }

    // Top / bottom bright edges
    final edgeH = 6.0;
    final topGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFF6600).withOpacity(0.6),
        Colors.transparent,
      ],
    );
    final topRect = Rect.fromLTWH(0, -edgeH, size.x, edgeH * 2);
    canvas.drawRect(topRect, Paint()..shader = topGrad.createShader(topRect));

    final botGrad = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        const Color(0xFFFF6600).withOpacity(0.6),
        Colors.transparent,
      ],
    );
    final botRect = Rect.fromLTWH(0, size.y - edgeH, size.x, edgeH * 2);
    canvas.drawRect(botRect, Paint()..shader = botGrad.createShader(botRect));
  }
}

class _Flame {
  final double baseY;
  final double speed;
  final double amplitude;
  final double offset;
  final double baseSize;

  _Flame({
    required this.baseY,
    required this.speed,
    required this.amplitude,
    required this.offset,
    required this.baseSize,
  });
}

class _Ember {
  double x, y, vx, vy, size, life, maxLife;

  _Ember({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.maxLife,
  }) : life = 0;

  static final _rng = Random();

  static _Ember spawn(Vector2 wallSize) {
    return _Ember(
      x: wallSize.x * 0.5 + (_rng.nextDouble() - 0.5) * wallSize.x,
      y: _rng.nextDouble() * wallSize.y,
      vx: (_rng.nextDouble() - 0.5) * 30,
      vy: 20 + _rng.nextDouble() * 40,
      size: 1.5 + _rng.nextDouble() * 2.5,
      maxLife: 0.5 + _rng.nextDouble() * 1.0,
    );
  }

  void reset(Vector2 wallSize) {
    final r = _Ember.spawn(wallSize);
    x = r.x;
    y = r.y;
    vx = r.vx;
    vy = r.vy;
    size = r.size;
    maxLife = r.maxLife;
    life = 0;
  }
}
