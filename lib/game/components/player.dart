import 'dart:math' show sin, cos;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/patapon_data.dart';
import '../../models/powerup_type.dart';
import '../../screens/game_screen.dart' show LogicalDirection;
import '../pata_game.dart';
import 'enemy.dart';
import 'platform_block.dart';
import 'powerup_item.dart';
import 'projectile.dart';
import 'coin.dart';
import 'finish_flag.dart';
import 'particle_effect.dart';

class Player extends PositionComponent with KeyboardHandler, CollisionCallbacks, HasGameRef<PataGame> {
  final PataponData pataponData;

  late int hp;
  int ammo = 0;
  bool hasShield = false;
  String? activePowerUpLabel;
  int coins = 0;

  Vector2 velocity = Vector2.zero();
  bool _onGround = false;
  bool _facingRight = true;

  double _speedMultiplier = 1.0;
  double _rangeMultiplier = 1.0;
  double _powerUpTimer = 0;
  double _invincibleTimer = 0;
  double _attackCooldown = 0;
  double _shieldCooldownTimer = 0;

  // Animation state
  double _runPhase = 0;
  double _swingTimer = 0;
  double _breathPhase = 0;
  double _squashStretch = 1.0;
  bool _wasAirborne = false;

  final Set<LogicalKeyboardKey> _keysPressed = {};

  bool _mobileLeft = false;
  bool _mobileRight = false;
  bool _mobileJump = false;
  bool _mobileAttack = false;

  void simulateKey(LogicalDirection dir, bool pressed) {
    switch (dir) {
      case LogicalDirection.left:
        _mobileLeft = pressed;
      case LogicalDirection.right:
        _mobileRight = pressed;
      case LogicalDirection.up:
        _mobileJump = pressed;
      case LogicalDirection.attack:
        _mobileAttack = pressed;
    }
  }

  Player({required this.pataponData}) {
    hp = pataponData.maxHp;
    if (pataponData.id == 'grillak') ammo = 5;
  }

  @override
  Future<void> onLoad() async {
    size = Vector2(40, 48);
    position = Vector2(100, 200);
    add(RectangleHitbox());
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if ((gameRef).gameOver || (gameRef).levelComplete) return;

    final wasInAir = !_onGround;
    _handleMovement(dt);
    _applyGravity(dt);
    _updateTimers(dt);

    position += velocity * dt;

    // Dust on landing
    if (_wasAirborne && _onGround) {
      gameRef.world.add(DustEffect(pos: Vector2(position.x + size.x / 2, position.y + size.y)));
      _squashStretch = 0.7;
    }
    _wasAirborne = !_onGround;

    if (position.y > 800) {
      hp = 0;
      (gameRef).onPlayerDied();
    }
  }

  void _handleMovement(double dt) {
    final moveSpeed = pataponData.speed * _speedMultiplier;

    final goLeft = _mobileLeft ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        _keysPressed.contains(LogicalKeyboardKey.keyA);
    final goRight = _mobileRight ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        _keysPressed.contains(LogicalKeyboardKey.keyD);

    if (goLeft) {
      velocity.x = -moveSpeed;
      _facingRight = false;
    } else if (goRight) {
      velocity.x = moveSpeed;
      _facingRight = true;
    } else {
      velocity.x = 0;
    }

    final wantJump = _mobileJump ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        _keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.space);

    if (wantJump && _onGround) {
      velocity.y = -pataponData.jumpForce;
      _onGround = false;
    }

    if (_mobileAttack ||
        _keysPressed.contains(LogicalKeyboardKey.keyX) ||
        _keysPressed.contains(LogicalKeyboardKey.keyZ)) {
      _attack();
    }
  }

  void _applyGravity(double dt) {
    velocity.y += 800 * dt; // gravity
    velocity.y = velocity.y.clamp(-500, 600);
  }

  void _updateTimers(double dt) {
    if (_powerUpTimer > 0) {
      _powerUpTimer -= dt;
      if (_powerUpTimer <= 0) {
        _speedMultiplier = 1.0;
        _rangeMultiplier = 1.0;
        activePowerUpLabel = null;
      }
    }
    if (_invincibleTimer > 0) _invincibleTimer -= dt;
    if (_attackCooldown > 0) _attackCooldown -= dt;
    if (_shieldCooldownTimer > 0) _shieldCooldownTimer -= dt;
    if (_swingTimer > 0) _swingTimer -= dt;

    _breathPhase += dt * 2.5;

    if (velocity.x.abs() > 10) {
      _runPhase += dt * 10;
    } else {
      _runPhase = 0;
    }

    if (!_onGround && velocity.y < -100) {
      _squashStretch = 1.2;
    } else if (!_onGround && velocity.y > 100) {
      _squashStretch = 0.85;
    } else {
      _squashStretch += (1.0 - _squashStretch) * 8 * dt;
    }
  }

  void _attack() {
    if (_attackCooldown > 0) return;
    _attackCooldown = 0.3;
    _swingTimer = 0.25;

    if (ammo > 0) {
      ammo--;
      final dir = _facingRight ? 1.0 : -1.0;
      gameRef.world.add(Projectile(
        startPos: position + Vector2(dir * 20, 10),
        direction: dir,
        damage: pataponData.attackDamage,
      ));
    }

    // Melee hit check for characters without ammo
    final meleeRange = pataponData.attackRange * _rangeMultiplier;
    final dir = _facingRight ? 1.0 : -1.0;
    for (final child in gameRef.world.children) {
      if (child is Enemy && !child.isDead) {
        final dx = child.position.x - position.x;
        if (dx * dir > 0 && dx.abs() < meleeRange && (child.position.y - position.y).abs() < 40) {
          child.hit(pataponData.attackDamage);
        }
      }
    }
  }

  void takeDamage(int damage) {
    if (_invincibleTimer > 0) return;

    if (hasShield) {
      hasShield = false;
      _invincibleTimer = 0.5;
      return;
    }

    if (pataponData.id == 'zieloniak' && _shieldCooldownTimer <= 0) {
      _shieldCooldownTimer = 5.0;
      _invincibleTimer = 0.5;
      return;
    }

    final actualDamage = pataponData.id == 'drewniak'
        ? (damage * 0.5).ceil()
        : damage;

    hp -= actualDamage;
    _invincibleTimer = 1.0;

    if (hp <= 0) {
      hp = 0;
      (gameRef).onPlayerDied();
    }
  }

  void collectPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.extraAmmo:
        ammo += 5;
      case PowerUpType.speedBoost:
        _speedMultiplier = 1.5;
        _powerUpTimer = type.duration;
        activePowerUpLabel = type.label;
      case PowerUpType.shield:
        hasShield = true;
      case PowerUpType.bigWeapon:
        _rangeMultiplier = 2.0;
        _powerUpTimer = type.duration;
        activePowerUpLabel = type.label;
      case PowerUpType.heal:
        hp = (hp + 2).clamp(0, pataponData.maxHp);
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is PlatformBlock) {
      _handlePlatformCollision(other, intersectionPoints);
    } else if (other is Enemy && !other.isDead) {
      final playerBottom = position.y + size.y;
      final enemyTop = other.position.y;
      if (playerBottom - enemyTop < 15 && velocity.y > 0) {
        velocity.y = -250;
        other.stomp();
        gameRef.world.add(StompEffect(pos: other.position + other.size / 2));
      } else {
        takeDamage(other.damage);
      }
    } else if (other is PowerUpItem && !other.collected) {
      other.collect();
      collectPowerUp(other.type);
      gameRef.world.add(CollectEffect(pos: other.position + other.size / 2, color: other.type.color));
    } else if (other is Coin && !other.collected) {
      other.collect();
      coins++;
      gameRef.world.add(CollectEffect(pos: other.position + other.size / 2, color: const Color(0xFFFFD700)));
    } else if (other is FinishFlag) {
      (gameRef).onLevelComplete();
    }
  }

  void _handlePlatformCollision(PlatformBlock block, Set<Vector2> points) {
    if (points.length < 2) return;

    final mid = (points.first + points.last) / 2;
    final playerCenter = position + size / 2;
    final diff = mid - playerCenter;

    if (diff.y.abs() > diff.x.abs()) {
      if (diff.y < 0) {
        // hitting ceiling
        velocity.y = 0;
      } else {
        // landing on platform
        position.y = block.position.y - size.y;
        velocity.y = 0;
        _onGround = true;
      }
    } else {
      if (diff.x < 0) {
        position.x = block.position.x + block.size.x;
      } else {
        position.x = block.position.x - size.x;
      }
      velocity.x = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_invincibleTimer > 0 && (_invincibleTimer * 10).toInt() % 2 == 0) return;

    final bodyPaint = Paint()..color = pataponData.themeColor;
    final eyeWhite = Paint()..color = Colors.white;
    final pupil = Paint()..color = Colors.black;
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy + 4);
    canvas.scale(1.0 / _squashStretch, _squashStretch);
    canvas.translate(-cx, -(cy + 4));

    // Breathing
    final breathScale = 1.0 + sin(_breathPhase) * 0.02;

    // Body
    canvas.drawCircle(Offset(cx, cy + 4), 18 * breathScale, Paint()..color = Colors.black);

    // Eye
    canvas.drawCircle(Offset(cx, cy + 2), 11, eyeWhite);
    canvas.drawCircle(
      Offset(cx + (_facingRight ? 3 : -3), cy + 2),
      5,
      pupil,
    );

    // Hat / accent
    final hatRect = Rect.fromLTWH(cx - 12, 0, 24, 12);
    canvas.drawRect(hatRect, bodyPaint);

    // Animated legs
    final legPaint = Paint()..color = Colors.black..strokeWidth = 3..style = PaintingStyle.stroke;
    final legSwing = sin(_runPhase) * 6;
    canvas.drawLine(
      Offset(cx - 6, cy + 20),
      Offset(cx - 8 + legSwing, size.y - 2),
      legPaint,
    );
    canvas.drawLine(
      Offset(cx + 6, cy + 20),
      Offset(cx + 8 - legSwing, size.y - 2),
      legPaint,
    );

    // Sword swing animation
    if (_swingTimer > 0) {
      final swingProgress = 1.0 - (_swingTimer / 0.25);
      final swingAngle = -1.2 + swingProgress * 2.4;
      final weaponDir = _facingRight ? 1.0 : -1.0;
      final swordPaint = Paint()..color = Colors.grey.shade300..strokeWidth = 3..strokeCap = StrokeCap.round;

      final swordLen = pataponData.attackRange.clamp(30, 60) * _rangeMultiplier * 0.6;
      final startX = cx + weaponDir * 14;
      final startY = cy;
      final endX = startX + cos(swingAngle) * swordLen * weaponDir;
      final endY = startY + sin(swingAngle) * swordLen;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), swordPaint);
      // Sword tip
      canvas.drawCircle(Offset(endX, endY), 3, Paint()..color = pataponData.themeColor);
    } else if (ammo > 0) {
      // Weapon (sausage) indicator
      final weaponX = _facingRight ? size.x - 4 : 4.0;
      canvas.drawCircle(Offset(weaponX, cy), 4, Paint()..color = Colors.orange);
    }

    // Shield indicator
    if (hasShield) {
      canvas.drawCircle(
        Offset(cx, cy + 4),
        22,
        Paint()..color = Colors.blue.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 3,
      );
    }

    canvas.restore();
  }
}
