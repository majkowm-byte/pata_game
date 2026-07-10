import 'dart:math' show Random, sin, cos, pi;
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'lightning_pickup.dart';
import 'fire_breath.dart';
import '../pata_game.dart';

class Enemy extends PositionComponent with CollisionCallbacks, HasGameRef<PataGame> {
  final int damage;
  final double patrolSpeed;
  final double patrolRange;

  static final Random _rng = Random();

  late final int maxHp;
  late final bool isBoss;
  int _currentHp = 0;
  bool isDead = false;
  double _startX = 0;
  double _direction = 1;
  double _deathTimer = 0;
  bool _droppedLoot = false;

  double _bobPhase = 0;
  double _runPhase = 0;
  double _hitFlashTimer = 0;
  double _angryPulse = 0;
  double _squash = 1.0;

  double debuffTimer = 0;
  Color? debuffColor;
  double _speedScale = 1.0;

  double burnTimer = 0;
  double _burnTick = 0;

  // Boss fire breath
  static const double _fireRange = 200;
  static const double _fireChance = 0.55;
  bool _fireRolled = false;
  double _bendTimer = 0;
  bool _breathing = false;
  double _fireCooldown = 0;

  Enemy({
    required Vector2 pos,
    this.damage = 1,
    int hp = 4,
    this.patrolSpeed = 60,
    this.patrolRange = 100,
  }) {
    position = pos;
    _startX = pos.x;

    // 20% chance to be a boss (2x size, 7 HP)
    isBoss = _rng.nextDouble() < 0.2;
    if (isBoss) {
      maxHp = 7;
    } else {
      maxHp = hp < 4 ? 4 : hp;
    }
  }

  @override
  Future<void> onLoad() async {
    if (isBoss) {
      size = Vector2(72, 72);
      position.y -= 36;
    } else {
      size = Vector2(36, 36);
    }
    _currentHp = maxHp;
    add(RectangleHitbox());
  }

  void applyDebuff({required double duration, double speedScale = 0.0, Color? color}) {
    debuffTimer = duration;
    _speedScale = speedScale;
    debuffColor = color;
  }

  /// Burning: takes 1 damage every second for [duration] seconds.
  void applyBurn(double duration) {
    burnTimer = duration;
    _burnTick = 1.0;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      _deathTimer += dt;
      _squash += (3.0 - _squash) * 6 * dt;
      if (!_droppedLoot) {
        _droppedLoot = true;
        final drops = isBoss ? 3 : 1;
        for (int i = 0; i < drops; i++) {
          parent?.add(LightningPickup(pos: Vector2(
            position.x + size.x / 2 - 10 + (i - 1) * 15,
            position.y,
          )));
        }
      }
      if (_deathTimer > 0.6) removeFromParent();
      return;
    }

    if (debuffTimer > 0) {
      debuffTimer -= dt;
      if (debuffTimer <= 0) {
        _speedScale = 1.0;
        debuffColor = null;
      }
    }

    if (burnTimer > 0) {
      burnTimer -= dt;
      _burnTick -= dt;
      if (_burnTick <= 0) {
        _burnTick = 1.0;
        hit(1);
      }
    }

    _bobPhase += dt * 5;
    _runPhase += dt * 8;
    _angryPulse += dt * 3;
    if (_hitFlashTimer > 0) _hitFlashTimer -= dt;

    // Boss fire breath logic
    if (isBoss && _speedScale > 0) {
      if (_fireCooldown > 0) _fireCooldown -= dt;
      if (_bendTimer > 0) {
        _bendTimer -= dt;
        if (_bendTimer <= 0 && _breathing) {
          _breathing = false;
          _fireCooldown = 3.0;
          _fireRolled = false;
          final dir = _direction;
          final spawnX = position.x + size.x / 2 + dir * size.x * 0.6;
          final spawnY = position.y + size.y * 0.5;
          for (int i = 0; i < 3; i++) {
            gameRef.world.add(FireBreath(
              startPos: Vector2(spawnX, spawnY + (i - 1) * 10),
              direction: dir,
              delay: i * 0.12,
            ));
          }
        }
      } else if (_fireCooldown <= 0) {
        final player = gameRef.player;
        final dx = (player.position.x + player.size.x / 2) - (position.x + size.x / 2);
        final inRange = dx.abs() < _fireRange;
        if (inRange && !_fireRolled) {
          _fireRolled = true;
          if (_rng.nextDouble() < _fireChance) {
            _direction = dx > 0 ? 1 : -1;
            _breathing = true;
            _bendTimer = 0.5;
          }
        } else if (!inRange) {
          _fireRolled = false;
        }
      }
    }

    if (_bendTimer > 0) {
      _squash += (1.0 - _squash) * 10 * dt;
      return;
    }

    position.x += patrolSpeed * _direction * _speedScale * dt;

    final drift = position.x - _startX;
    if (drift.abs() > patrolRange) {
      _direction = drift > 0 ? -1 : 1;
      position.x = _startX + patrolRange * (drift > 0 ? 1 : -1);
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
    if (_currentHp <= 0) {
      _currentHp = 0;
      isDead = true;
    }
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final scale = isBoss ? 2.0 : 1.0;

    if (isDead) {
      _renderDead(canvas, cx, cy);
      return;
    }

    final isFlashing = _hitFlashTimer > 0;
    final bob = sin(_bobPhase) * 2;
    final pulse = 1.0 + sin(_angryPulse) * 0.03;
    final hasDebuff = debuffTimer > 0;

    canvas.save();
    canvas.translate(cx, size.y);
    canvas.scale(1.0 / _squash, _squash);
    // Boss bend-down animation for fire breath
    if (isBoss && _bendTimer > 0) {
      final bendAngle = _direction * 0.35 * (_bendTimer / 0.5);
      canvas.rotate(bendAngle);
    }
    canvas.translate(-cx, -size.y);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.y + 2), width: 28 * scale, height: 6 * scale),
      Paint()..color = Colors.black.withOpacity(0.15),
    );

    // Legs
    final legSwing = sin(_runPhase) * 5 * _speedScale;
    final legPaint = Paint()..color = const Color(0xFF8B0000)..strokeWidth = 2.5 * scale..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 6 * scale, cy + 14 * scale + bob), Offset(cx - 8 * scale + legSwing, size.y), legPaint);
    canvas.drawLine(Offset(cx + 6 * scale, cy + 14 * scale + bob), Offset(cx + 8 * scale - legSwing, size.y), legPaint);

    // Body
    Color bodyColor;
    if (isFlashing) {
      bodyColor = Colors.white;
    } else if (hasDebuff && debuffColor != null) {
      bodyColor = Color.lerp(const Color(0xFF8B0000), debuffColor!, 0.5)!;
    } else {
      bodyColor = const Color(0xFF8B0000);
    }

    // Boss has a darker/angrier shade
    if (isBoss) {
      bodyColor = Color.lerp(bodyColor, Colors.black, 0.2)!;
    }

    canvas.drawCircle(Offset(cx, cy + bob), 16 * pulse * scale, Paint()..color = bodyColor);

    // Debuff ring
    if (hasDebuff) {
      canvas.drawCircle(
        Offset(cx, cy + bob),
        18 * scale,
        Paint()..color = (debuffColor ?? Colors.cyan).withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 2,
      );
    }

    // Eye
    if (hasDebuff && _speedScale == 0) {
      final spiralPaint = Paint()..color = Colors.yellow..strokeWidth = 1.5..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cx, cy - 1 * scale + bob), 6 * scale, Paint()..color = Colors.yellow);
      canvas.drawCircle(Offset(cx, cy - 1 * scale + bob), 4 * scale, spiralPaint);
      canvas.drawCircle(Offset(cx, cy - 1 * scale + bob), 2 * scale, spiralPaint);
    } else {
      canvas.drawCircle(Offset(cx, cy - 1 * scale + bob), 8 * scale, Paint()..color = Colors.yellow);
      canvas.drawCircle(Offset(cx + _direction * 3 * scale, cy - 1 * scale + bob), 4 * scale, Paint()..color = Colors.black);
    }

    // Eyebrow
    final browPaint = Paint()..color = const Color(0xFF5a0000)..strokeWidth = 2.5 * scale..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 7 * scale, cy - 9 * scale + bob), Offset(cx, cy - 6 * scale + bob), browPaint);
    canvas.drawLine(Offset(cx + 7 * scale, cy - 9 * scale + bob), Offset(cx, cy - 6 * scale + bob), browPaint);

    // Horns
    final hornWobble = sin(_bobPhase * 1.3) * 1.5;
    final hornPaint = Paint()..color = const Color(0xFFAA2222)..strokeWidth = 3 * scale..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 8 * scale, cy - 14 * scale + bob), Offset(cx - 12 * scale + hornWobble, cy - 24 * scale + bob), hornPaint);
    canvas.drawLine(Offset(cx + 8 * scale, cy - 14 * scale + bob), Offset(cx + 12 * scale - hornWobble, cy - 24 * scale + bob), hornPaint);

    // Boss crown
    if (isBoss) {
      final crownPaint = Paint()..color = const Color(0xFFFFD700);
      final crownTop = cy - 26 * scale + bob;
      canvas.drawRect(Rect.fromLTWH(cx - 10, crownTop, 20, 6), crownPaint);
      canvas.drawCircle(Offset(cx - 8, crownTop - 2), 3, crownPaint);
      canvas.drawCircle(Offset(cx, crownTop - 4), 3, crownPaint);
      canvas.drawCircle(Offset(cx + 8, crownTop - 2), 3, crownPaint);
    }

    canvas.restore();

    // HP hearts above head
    _renderHearts(canvas, cx, cy + bob);
  }

  void _renderHearts(Canvas canvas, double cx, double topBob) {
    final heartCount = maxHp;
    final heartsPerRow = isBoss ? 7 : 4;
    final heartSize = isBoss ? 7.0 : 6.0;
    final spacing = heartSize + 2;
    final totalWidth = heartsPerRow * spacing - 2;
    final startX = cx - totalWidth / 2;
    final heartY = isBoss ? -35.0 : -18.0;

    for (int i = 0; i < heartCount; i++) {
      final row = i ~/ heartsPerRow;
      final col = i % heartsPerRow;
      final hx = startX + col * spacing + heartSize / 2;
      final hy = heartY - row * (heartSize + 2) + topBob;

      final isFull = i < _currentHp;
      _drawHeart(canvas, hx, hy, heartSize, isFull);
    }
  }

  void _drawHeart(Canvas canvas, double x, double y, double s, bool full) {
    final paint = Paint()..color = full ? Colors.red : Colors.red.withOpacity(0.25);
    final r = s / 2;
    // Two circles + triangle to form a heart
    canvas.drawCircle(Offset(x - r * 0.5, y - r * 0.3), r * 0.55, paint);
    canvas.drawCircle(Offset(x + r * 0.5, y - r * 0.3), r * 0.55, paint);
    final path = ui.Path();
    path.moveTo(x - r, y);
    path.lineTo(x, y + r * 0.9);
    path.lineTo(x + r, y);
    path.close();
    canvas.drawPath(path, paint);
  }

  void _renderDead(Canvas canvas, double cx, double cy) {
    final deathProgress = (_deathTimer / 0.6).clamp(0.0, 1.0);
    final opacity = 1.0 - deathProgress;
    final scale = isBoss ? 2.0 : 1.0;

    canvas.save();
    canvas.translate(cx, size.y);
    canvas.scale(1.0 + deathProgress * 0.5, 1.0 - deathProgress * 0.8);
    canvas.translate(-cx, -size.y);

    canvas.drawCircle(
      Offset(cx, cy),
      16 * scale,
      Paint()..color = const Color(0xFF8B0000).withOpacity(opacity),
    );
    final xPaint = Paint()..color = Colors.white.withOpacity(opacity)..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 5 * scale, cy - 3 * scale), Offset(cx - 1 * scale, cy + 1 * scale), xPaint);
    canvas.drawLine(Offset(cx - 5 * scale, cy + 1 * scale), Offset(cx - 1 * scale, cy - 3 * scale), xPaint);
    canvas.drawLine(Offset(cx + 1 * scale, cy - 3 * scale), Offset(cx + 5 * scale, cy + 1 * scale), xPaint);
    canvas.drawLine(Offset(cx + 1 * scale, cy + 1 * scale), Offset(cx + 5 * scale, cy - 3 * scale), xPaint);

    for (int i = 0; i < 3; i++) {
      final angle = deathProgress * pi * 2 + i * pi * 2 / 3;
      final starX = cx + cos(angle) * 14 * scale;
      final starY = cy - 18 * scale + sin(angle) * 4;
      canvas.drawCircle(Offset(starX, starY), 2, Paint()..color = Colors.yellow.withOpacity(opacity));
    }

    canvas.restore();
  }
}
