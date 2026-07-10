import 'dart:math' show Random, sin, cos, pi, max;
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/boss_data.dart';
import '../pata_game.dart';
import 'particle_effect.dart';
import 'boss_arena.dart';
import 'coin.dart';
import 'lightning_pickup.dart';

class Boss extends PositionComponent with CollisionCallbacks, HasGameRef<PataGame> {
  final BossData data;

  late int maxHp;
  int _currentHp = 0;
  bool isDead = false;

  ui.Image? _sprite;
  static final _rng = Random();

  // Animation phases
  double _breathPhase = 0;
  double _swayPhase = 0;
  double _angryPhase = 0;

  // Hit flash
  double _hitFlashTimer = 0;
  double _squash = 1.0;

  // Debuff (special boss rules)
  double debuffTimer = 0;
  Color? debuffColor;
  double _speedScale = 1.0;

  // Burn
  double burnTimer = 0;
  double _burnTick = 0;
  double _burnParticleTimer = 0;

  // Death animation
  double _deathTimer = 0;
  bool _portalSpawned = false;
  bool _deathFlashDone = false;

  // Movement (slow patrol in arena)
  double _direction = -1;
  double _startX = 0;

  final BossArena arena;

  Boss({required this.data, required Vector2 pos, required this.arena}) {
    position = pos;
  }

  @override
  Future<void> onLoad() async {
    maxHp = data.hp;
    _currentHp = maxHp;

    _startX = position.x;

    try {
      final bytes = await rootBundle.load(data.spritePath);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _sprite = frame.image;
    } catch (_) {}

    // Size from sprite aspect ratio — base height 120, width scaled to match
    final baseH = 120.0 * data.spriteScale;
    if (_sprite != null && _sprite!.height > 0) {
      final aspect = _sprite!.width / _sprite!.height;
      size = Vector2(baseH * aspect, baseH);
    } else {
      size = Vector2(baseH, baseH);
    }

    add(RectangleHitbox());
  }

  // Boss debuff rules: stun max 2s, slow max 3s
  void applyDebuff({required double duration, double speedScale = 0.0, Color? color}) {
    if (speedScale == 0.0) {
      debuffTimer = duration.clamp(0, 2);
    } else {
      debuffTimer = duration.clamp(0, 3);
    }
    _speedScale = speedScale;
    debuffColor = color;
  }

  // Knockback does NOT work on bosses
  void applyKnockback(double dx) {
    // intentionally empty
  }

  void applyBurn(double duration) {
    burnTimer = duration;
    _burnTick = 1.0;
  }

  void hit(int damage) {
    if (isDead) return;
    _currentHp -= damage;
    _hitFlashTimer = 0.2;
    _squash = 0.75;

    // Hit particles
    final cx = position.x + size.x / 2;
    final cy = position.y + size.y / 2;
    for (int i = 0; i < 6; i++) {
      gameRef.world.add(_BossHitParticle(
        pos: Vector2(cx + (_rng.nextDouble() - 0.5) * size.x * 0.6, cy + (_rng.nextDouble() - 0.5) * size.y * 0.4),
      ));
    }

    gameRef.screenFlashTimer = 0.08;

    if (_currentHp <= 0) {
      _currentHp = 0;
      isDead = true;
    }
  }

  void stomp() {
    hit(1);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      _updateDeath(dt);
      return;
    }

    // Animations
    _breathPhase += dt * 2.5;
    _swayPhase += dt * 1.8;
    _angryPhase += dt * 3.0;

    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;
    _squash += (1.0 - _squash) * 6 * dt;

    // Debuff timer
    if (debuffTimer > 0) {
      debuffTimer -= dt;
      if (debuffTimer <= 0) {
        _speedScale = 1.0;
        debuffColor = null;
      }
    }

    // Burn
    if (burnTimer > 0) {
      burnTimer -= dt;
      _burnTick -= dt;
      if (_burnTick <= 0) {
        _burnTick = 1.0;
        hit(1);
      }
      _burnParticleTimer -= dt;
      if (_burnParticleTimer <= 0) {
        _burnParticleTimer = 0.1;
        gameRef.world.add(_BossFireParticle(
          pos: Vector2(
            position.x + size.x * 0.2 + _rng.nextDouble() * size.x * 0.6,
            position.y + size.y * 0.3,
          ),
        ));
      }
    }

    // Slow patrol movement
    final speed = 25.0 * _speedScale;
    position.x += speed * _direction * dt;
    final drift = position.x - _startX;
    if (drift.abs() > 80) {
      _direction = -_direction;
    }
  }

  void _updateDeath(double dt) {
    _deathTimer += dt;

    if (_deathTimer < 0.3 && !_deathFlashDone) {
      gameRef.screenFlashTimer = 0.3;
      _deathFlashDone = true;
    }

    // Spawn particles during death
    if (_deathTimer < 2.0) {
      final cx = position.x + size.x / 2;
      final cy = position.y + size.y / 2;
      if (_rng.nextDouble() < 0.4) {
        gameRef.world.add(_BossDeathParticle(
          pos: Vector2(
            cx + (_rng.nextDouble() - 0.5) * size.x,
            cy + (_rng.nextDouble() - 0.5) * size.y,
          ),
          color: _getRandomDeathColor(),
        ));
      }
    }

    // Remove right wall, spawn portal + loot after death animation
    if (_deathTimer > 2.5 && !_portalSpawned) {
      _portalSpawned = true;
      arena.onBossDied();

      final cx = position.x + size.x / 2;
      for (int i = 0; i < 5; i++) {
        gameRef.world.add(LightningPickup(
          pos: Vector2(cx - 60 + i * 30.0, 460),
        ));
      }
      for (int i = 0; i < 3; i++) {
        gameRef.world.add(Coin(
          pos: Vector2(cx - 30 + i * 30.0, 440),
        ));
      }
    }

    if (_deathTimer > 3.5) {
      removeFromParent();
    }
  }

  Color _getRandomDeathColor() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.white,
      const Color(0xFFFF4500),
      const Color(0xFFFFD700),
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  @override
  void render(Canvas canvas) {
    if (isDead) {
      _renderDeath(canvas);
      return;
    }

    final cx = size.x / 2;
    final cy = size.y / 2;

    final breathScale = 1.0 + sin(_breathPhase) * 0.03;
    final sway = sin(_swayPhase) * 3.0;

    canvas.save();
    canvas.translate(cx, size.y);
    canvas.scale(breathScale / _squash, _squash * breathScale);
    canvas.translate(-cx + sway, -size.y);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.y + 4), width: size.x * 0.7, height: 12),
      Paint()..color = Colors.black.withOpacity(0.2),
    );

    // Sprite
    if (_sprite != null) {
      final paint = Paint()..filterQuality = FilterQuality.medium;

      if (_hitFlashTimer > 0) {
        paint.colorFilter = const ColorFilter.mode(Colors.white, BlendMode.srcATop);
      } else if (debuffTimer > 0 && debuffColor != null) {
        paint.colorFilter = ColorFilter.mode(
          debuffColor!.withOpacity(0.4), BlendMode.srcATop,
        );
      }

      final src = Rect.fromLTWH(0, 0, _sprite!.width.toDouble(), _sprite!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(_sprite!, src, dst, paint);
    } else {
      // Fallback: draw a big angry circle
      final color = _hitFlashTimer > 0 ? Colors.white : Colors.deepPurple;
      canvas.drawCircle(Offset(cx, cy), size.x * 0.4, Paint()..color = color);
      canvas.drawCircle(Offset(cx - 15, cy - 10), 8, Paint()..color = Colors.yellow);
      canvas.drawCircle(Offset(cx + 15, cy - 10), 8, Paint()..color = Colors.yellow);
      canvas.drawCircle(Offset(cx - 13, cy - 10), 4, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(cx + 17, cy - 10), 4, Paint()..color = Colors.black);
    }

    // Debuff ring
    if (debuffTimer > 0 && debuffColor != null) {
      canvas.drawCircle(
        Offset(cx, cy),
        size.x * 0.5,
        Paint()
          ..color = debuffColor!.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Burn overlay
    if (burnTimer > 0) {
      final burnPulse = (sin(burnTimer * 8) * 0.15 + 0.25).clamp(0.1, 0.4);
      canvas.drawCircle(
        Offset(cx, cy),
        size.x * 0.45,
        Paint()..color = Colors.red.withOpacity(burnPulse),
      );
    }

    // Angry aura pulse
    final auraPulse = sin(_angryPhase) * 0.1 + 0.1;
    canvas.drawCircle(
      Offset(cx, cy),
      size.x * 0.55,
      Paint()
        ..color = Colors.red.withOpacity(auraPulse.clamp(0.0, 0.2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.restore();

    // HP bar above boss
    _renderHpBar(canvas, cx);
  }

  void _renderHpBar(Canvas canvas, double cx) {
    final barWidth = size.x * 0.9;
    final barHeight = 8.0;
    final barX = cx - barWidth / 2;
    final barY = -20.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight), const Radius.circular(4)),
      Paint()..color = Colors.black.withOpacity(0.7),
    );

    // HP fill
    final hpFrac = _currentHp / maxHp;
    final fillColor = hpFrac > 0.5 ? Colors.red : (hpFrac > 0.25 ? Colors.orange : Colors.yellow);
    if (hpFrac > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barX + 1, barY + 1, (barWidth - 2) * hpFrac, barHeight - 2),
          const Radius.circular(3),
        ),
        Paint()..color = fillColor,
      );
    }

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barWidth, barHeight), const Radius.circular(4)),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Boss name
    final textPainter = TextPainter(
      text: TextSpan(
        text: data.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, barY - 14));
  }

  void _renderDeath(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final progress = (_deathTimer / 2.5).clamp(0.0, 1.0);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final shakeX = sin(_deathTimer * 40) * (1.0 - progress) * 8;
    final shakeY = cos(_deathTimer * 35) * (1.0 - progress) * 5;
    final deathScale = 1.0 + progress * 0.3;

    canvas.save();
    canvas.translate(cx + shakeX, cy + shakeY);
    canvas.scale(deathScale);
    canvas.translate(-cx, -cy);

    if (_sprite != null) {
      final paint = Paint()
        ..filterQuality = FilterQuality.medium
        ..color = Color.fromRGBO(255, 255, 255, opacity);

      // Red tint during death
      if (progress > 0.3) {
        paint.colorFilter = ColorFilter.mode(
          Colors.red.withOpacity(0.5),
          BlendMode.srcATop,
        );
      }

      final src = Rect.fromLTWH(0, 0, _sprite!.width.toDouble(), _sprite!.height.toDouble());
      final dst = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(_sprite!, src, dst, paint);
    }

    // Explosion rings
    if (progress > 0.2) {
      final ringProgress = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
      for (int i = 0; i < 3; i++) {
        final ringR = size.x * 0.3 + ringProgress * size.x * (0.5 + i * 0.3);
        final ringOpacity = (1.0 - ringProgress) * 0.6;
        canvas.drawCircle(
          Offset(cx, cy),
          ringR,
          Paint()
            ..color = [Colors.orange, Colors.red, Colors.yellow][i].withOpacity(ringOpacity.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 - i.toDouble(),
        );
      }
    }

    canvas.restore();
  }
}

// Hit effect particle
class _BossHitParticle extends PositionComponent {
  double _life = 0;
  static const _maxLife = 0.4;
  static final _rng = Random();
  final double _dx;
  final double _dy;

  _BossHitParticle({required Vector2 pos})
      : _dx = (_rng.nextDouble() - 0.5) * 200,
        _dy = -_rng.nextDouble() * 150 - 50 {
    position = pos;
    size = Vector2.all(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.x += _dx * dt;
    position.y += _dy * dt;
    if (_life > _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / _maxLife;
    final r = 4 + (1.0 - progress) * 4;
    final opacity = (1.0 - progress) * 0.9;
    final color = Color.lerp(Colors.white, Colors.orange, progress)!;
    canvas.drawCircle(Offset.zero, r, Paint()..color = color.withOpacity(opacity));
  }
}

// Fire particle on boss when burning
class _BossFireParticle extends PositionComponent {
  double _life = 0;
  static const _maxLife = 0.5;
  static final _rng = Random();
  final double _drift;

  _BossFireParticle({required Vector2 pos})
      : _drift = (_rng.nextDouble() - 0.5) * 40 {
    position = pos;
    size = Vector2.all(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 50 * dt;
    position.x += _drift * dt;
    if (_life > _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / _maxLife;
    final r = 3 + (1.0 - progress) * 4;
    final opacity = (1.0 - progress) * 0.8;
    final color = Color.lerp(Colors.yellow, Colors.red, progress)!;
    canvas.drawCircle(Offset.zero, r, Paint()..color = color.withOpacity(opacity));
  }
}

// Death explosion particle
class _BossDeathParticle extends PositionComponent {
  double _life = 0;
  static const _maxLife = 1.2;
  static final _rng = Random();
  final double _dx;
  final double _dy;
  final Color color;

  _BossDeathParticle({required Vector2 pos, required this.color})
      : _dx = (_rng.nextDouble() - 0.5) * 300,
        _dy = (_rng.nextDouble() - 0.5) * 300 - 100 {
    position = pos;
    size = Vector2.all(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.x += _dx * dt;
    position.y += _dy * dt;
    if (_life > _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / _maxLife;
    final r = 3 + (1.0 - progress) * 6;
    final opacity = (1.0 - progress) * 0.8;
    canvas.drawCircle(Offset.zero, r, Paint()..color = color.withOpacity(opacity.clamp(0.0, 1.0)));
  }
}
