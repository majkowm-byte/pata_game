import 'dart:math' show Random, sin, cos, pi;
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/patapon_data.dart';
import '../../models/potion_type.dart';
import '../../models/powerup_type.dart';
import '../../screens/game_screen.dart' show LogicalDirection;
import '../pata_game.dart';
import '../audio/retro_sfx.dart';
import 'enemy.dart';
import 'platform_block.dart';
import 'powerup_item.dart';
import 'projectile.dart';
import 'coin.dart';
import 'finish_flag.dart';
import 'boss.dart';
import 'boss_portal.dart';
import 'boss_arena.dart';
import 'particle_effect.dart';
import 'lightning_pickup.dart';
import 'mystery_box.dart';
import 'potion.dart';

class Player extends PositionComponent with KeyboardHandler, CollisionCallbacks, HasGameRef<PataGame> {
  final PataponData pataponData;

  late int hp;
  int ammo = 0;
  bool hasShield = false;
  double shieldPowerUpTimer = 0;
  bool hasAngelProtection = false;
  String? activePowerUpLabel;
  int coins = 0;
  int lightnings = 0;

  int weaponLevel = 0;
  double weaponMultiplier = 1.0;
  int nextUpgradeCost = 10;
  double _goldFlashTimer = 0;

  int speedLevel = 0;
  int jumpLevel = 0;
  double _speedBonus = 1.0;
  double _jumpBonus = 1.0;

  int scaleStep = 0;
  double _sizeScale = 1.0;
  double _mobilityScale = 1.0;

  Vector2 velocity = Vector2.zero();
  bool _onGround = false;
  bool _facingRight = true;

  double _speedMultiplier = 1.0;
  double _rangeMultiplier = 1.0;
  double _powerUpTimer = 0;
  double _invincibleTimer = 0;
  double _attackCooldown = 0;
  double _burnTimer = 0;
  double _burnTick = 0;
  double _burnParticleTimer = 0;
  static final _rng = Random();
  double _shieldCooldownTimer = 0;
  double _offhandCooldown = 0;

  bool _jumping = false;
  bool _jumpReleased = true;
  double _jumpHoldTime = 0;
  static const double _maxJumpHoldTime = 0.25;
  static const double _jumpHoldForce = 600.0;

  // Sprites
  ui.Image? _bodyImage;
  ui.Image? _weaponImage;
  ui.Image? _legsImage;

  // Animation
  double _runPhase = 0;
  double _swingTimer = 0;
  static const double _swingDuration = 0.3;
  double _breathPhase = 0;
  double _squashStretch = 1.0;
  bool _wasAirborne = false;

  final Set<LogicalKeyboardKey> _keysPressed = {};

  bool _mobileLeft = false;
  bool _mobileRight = false;
  bool _mobileJump = false;
  bool _mobileAttack = false;
  bool _mobileAttackQueued = false;
  bool _mobileOffhand = false;
  bool _mobileOffhandQueued = false;

  bool _frozen = true;
  bool _visible = true;
  // Set by freeze() (boss intro, level end): input must not unfreeze the
  // player then, only unfreeze() does. The initial spawn freeze is soft.
  bool _inputLocked = false;

  void freeze() {
    _frozen = true;
    _inputLocked = true;
    _visible = false;
    velocity = Vector2.zero();
  }

  void unfreeze() {
    _frozen = false;
    _inputLocked = false;
    _visible = true;
  }

  void simulateKey(LogicalDirection dir, bool pressed) {
    if (pressed && !_inputLocked) _frozen = false;
    switch (dir) {
      case LogicalDirection.left:
        _mobileLeft = pressed;
      case LogicalDirection.right:
        _mobileRight = pressed;
      case LogicalDirection.up:
        _mobileJump = pressed;
      case LogicalDirection.attack:
        _mobileAttack = pressed;
        if (pressed) _mobileAttackQueued = true;
      case LogicalDirection.offhand:
        _mobileOffhand = pressed;
        if (pressed) _mobileOffhandQueued = true;
    }
  }

  Player({
    required this.pataponData,
    bool shieldMode = false,
    int persistCoins = 0,
    int persistLightnings = 0,
    int persistWeaponLevel = 0,
    int persistSpeedLevel = 0,
    int persistJumpLevel = 0,
    bool persistAngelProtection = false,
    int persistScaleStep = 0,
  }) {
    hp = pataponData.maxHp;
    coins = persistCoins;
    lightnings = persistLightnings;
    weaponLevel = persistWeaponLevel;
    speedLevel = persistSpeedLevel;
    jumpLevel = persistJumpLevel;
    hasAngelProtection = persistAngelProtection;
    scaleStep = persistScaleStep;
    recalcWeapon();
    recalcSpeed();
    recalcJump();
    _recalcScale();

    if (shieldMode) {
      ammo = 1000;
    } else if (pataponData.id == 'grillak') {
      ammo = 5;
    }
  }

  void _recalcCost() {
    nextUpgradeCost = (weaponLevel + speedLevel + jumpLevel + 1) * 10;
  }

  void recalcWeapon() {
    weaponMultiplier = 1.0 + weaponLevel * 0.5;
    _recalcCost();
  }

  void recalcSpeed() {
    const progression = [1.0, 1.3, 1.6, 1.9, 2.1];
    _speedBonus = speedLevel < progression.length ? progression[speedLevel] : 2.1;
    _recalcCost();
  }

  void recalcJump() {
    const progression = [1.0, 1.3, 1.6, 1.9, 2.1];
    _jumpBonus = jumpLevel < progression.length ? progression[jumpLevel] : 2.1;
    _recalcCost();
  }

  void _recalcScale() {
    if (scaleStep < 0) {
      final abs = scaleStep.abs();
      double s = 1.0;
      for (int i = 0; i < abs; i++) s *= 0.66;
      _sizeScale = s;
      _mobilityScale = 1.0 + 0.25 * abs;
    } else if (scaleStep > 0) {
      _sizeScale = 1.0 + 0.33 * scaleStep;
      double s = 1.0;
      for (int i = 0; i < scaleStep; i++) s *= 0.75;
      _mobilityScale = s;
    } else {
      _sizeScale = 1.0;
      _mobilityScale = 1.0;
    }
  }

  int get meleeDamage => scaleStep > 0 ? 2 : 1;

  // scaleStep persists across deaths and levels and the eagle drops a new box
  // on every attempt, so it is capped to keep the hero playable.
  static const int _maxScaleSteps = 2;

  void applyScaleStep(int delta) {
    scaleStep = (scaleStep + delta).clamp(-_maxScaleSteps, _maxScaleSteps);
    _recalcScale();
    final baseSize = Vector2(40, 48) * 1.33;
    final oldBottom = position.y + size.y;
    size = baseSize * _sizeScale;
    position.y = oldBottom - size.y;
  }

  @override
  Future<void> onLoad() async {
    // Base size scaled +33% so patapons read bigger on screen. Everything
    // (melee range, weapon render) derives from `size` + relative fractions,
    // so it scales in lockstep. Spawn Y is computed from size.y so the feet
    // stay planted on the ground (top = 500).
    size = Vector2(40, 48) * 1.33 * _sizeScale;
    if (position.x == 0 && position.y == 0) {
      position = Vector2(100, 500 - size.y);
    }
    add(RectangleHitbox());
    await _loadSprites();
  }

  Future<void> _loadSprites() async {
    try {
      final bodyData = await rootBundle.load(pataponData.spritePath);
      final bodyCodec = await ui.instantiateImageCodec(bodyData.buffer.asUint8List());
      final bodyFrame = await bodyCodec.getNextFrame();
      _bodyImage = bodyFrame.image;

      final weaponData = await rootBundle.load(pataponData.weaponSpritePath);
      final weaponCodec = await ui.instantiateImageCodec(weaponData.buffer.asUint8List());
      final weaponFrame = await weaponCodec.getNextFrame();
      _weaponImage = weaponFrame.image;

      if (pataponData.legsSpritePath.isNotEmpty) {
        final legsData = await rootBundle.load(pataponData.legsSpritePath);
        final legsCodec = await ui.instantiateImageCodec(legsData.buffer.asUint8List());
        final legsFrame = await legsCodec.getNextFrame();
        _legsImage = legsFrame.image;
      }
    } catch (_) {}
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.isNotEmpty && !_inputLocked) _frozen = false;
    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if ((gameRef).gameOver || (gameRef).levelComplete || (gameRef).transitioning) return;

    dt = dt.clamp(0, 0.05);

    if (!_frozen) {
      _handleMovement(dt);
    } else {
      velocity.x = 0;
    }
    _applyGravity(dt);
    _updateTimers(dt);

    position += velocity * dt;

    if (_wasAirborne && _onGround) {
      gameRef.world.add(DustEffect(pos: Vector2(position.x + size.x / 2, position.y + size.y)));
      _squashStretch = 0.7;
    }
    _wasAirborne = !_onGround;

    if (position.y > 800) {
      if (gameRef.shieldMode) {
        hasAngelProtection = false;
        velocity = Vector2.zero();
        _invincibleTimer = 1.5;
        final landX = _findNextPlatformX(position.x);
        position = Vector2(landX, 300);
      } else if (hasAngelProtection) {
        hasAngelProtection = false;
        _invincibleTimer = 1.5;
        velocity = Vector2.zero();
        final landX = _findNextPlatformX(position.x);
        position = Vector2(landX, 300);
      } else {
        hp = 0;
        (gameRef).onPlayerDied();
      }
    }
  }

  void _handleMovement(double dt) {
    final moveSpeed = pataponData.speed * _speedMultiplier * _speedBonus * _mobilityScale;

    final goLeft = _mobileLeft || _keysPressed.contains(LogicalKeyboardKey.arrowLeft) || _keysPressed.contains(LogicalKeyboardKey.keyA);
    final goRight = _mobileRight || _keysPressed.contains(LogicalKeyboardKey.arrowRight) || _keysPressed.contains(LogicalKeyboardKey.keyD);

    if (goLeft) {
      velocity.x = -moveSpeed;
      _facingRight = false;
    } else if (goRight) {
      velocity.x = moveSpeed;
      _facingRight = true;
    } else {
      velocity.x = 0;
    }

    final wantJump = _mobileJump || _keysPressed.contains(LogicalKeyboardKey.arrowUp) || _keysPressed.contains(LogicalKeyboardKey.keyW) || _keysPressed.contains(LogicalKeyboardKey.space);

    if (!wantJump) {
      _jumpReleased = true;
      _jumping = false;
    }

    if (wantJump && _onGround && _jumpReleased) {
      velocity.y = -pataponData.jumpForce * _jumpBonus * _mobilityScale;
      _onGround = false;
      _jumping = true;
      _jumpReleased = false;
      _jumpHoldTime = 0;
      RetroSfx.instance.jump();
    }

    if (wantJump && _jumping && _jumpHoldTime < _maxJumpHoldTime) {
      _jumpHoldTime += dt;
      velocity.y -= _jumpHoldForce * dt;
    }

    if (_mobileAttack || _mobileAttackQueued || _keysPressed.contains(LogicalKeyboardKey.keyX) || _keysPressed.contains(LogicalKeyboardKey.keyZ)) {
      _mobileAttackQueued = false;
      _attack();
    }

    if (_mobileOffhand || _mobileOffhandQueued || _keysPressed.contains(LogicalKeyboardKey.keyC)) {
      _mobileOffhandQueued = false;
      _offhandAttack();
    }
  }

  void _applyGravity(double dt) {
    velocity.y += 800 * dt;
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
    if (_burnTimer > 0) {
      _burnTimer -= dt;
      _burnTick -= dt;
      if (_burnTick <= 0) {
        _burnTick = 1.0;
        takeDamage(1);
      }
      _burnParticleTimer -= dt;
      if (_burnParticleTimer <= 0) {
        _burnParticleTimer = 0.08;
        gameRef.world.add(_PlayerFireParticle(
          pos: Vector2(
            position.x + size.x * 0.2 + _rng.nextDouble() * size.x * 0.6,
            position.y + size.y * 0.3,
          ),
        ));
      }
    }
    if (_attackCooldown > 0) _attackCooldown -= dt;
    if (_shieldCooldownTimer > 0) _shieldCooldownTimer -= dt;
    if (_swingTimer > 0) _swingTimer -= dt;
    if (shieldPowerUpTimer > 0) shieldPowerUpTimer -= dt;
    if (_goldFlashTimer > 0) _goldFlashTimer -= dt;
    if (_offhandCooldown > 0) _offhandCooldown -= dt;

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
    _swingTimer = _swingDuration;

    RetroSfx.instance.hit();

    if (ammo > 0) {
      ammo--;
      final dir = _facingRight ? 1.0 : -1.0;
      // Spawn from the lower-mid body (scales with size) so sausages travel at
      // enemy height instead of flying over their heads.
      gameRef.world.add(Projectile(
        startPos: position + Vector2(dir * size.x * 0.5, size.y * 0.62),
        direction: dir,
        damage: 1,
      ));
      return;
    }

    final wr = pataponData.weaponRegion;
    // Match the aspect-preserved rendered weapon width (height * image aspect),
    // falling back to the region ratio when the sprite hasn't loaded yet.
    final weaponBaseH = size.y * wr.height * 1.8;
    final imgAspect = _weaponImage != null
        ? _weaponImage!.width / _weaponImage!.height
        : (size.x * wr.width) / (size.y * wr.height);
    final weaponVisualW = weaponBaseH * imgAspect * weaponMultiplier;
    final meleeRange = weaponVisualW * _rangeMultiplier;
    final meleeDir = _facingRight ? 1.0 : -1.0;
    // Weapon sweeps out from the body's FRONT edge, so an adjacent enemy is
    // always in reach regardless of body/weapon size.
    final frontX = position.x + (_facingRight ? size.x : 0.0);
    final playerTop = position.y;
    final playerBottom = position.y + size.y;
    for (final child in gameRef.world.descendants()) {
      if (child is Enemy && !child.isDead) {
        final enemyLeft = child.position.x;
        final enemyRight = child.position.x + child.size.x;
        final nearEdge = _facingRight ? enemyLeft : enemyRight;
        final farEdge = _facingRight ? enemyRight : enemyLeft;
        final dxNear = (nearEdge - frontX) * meleeDir;
        final dxFar = (farEdge - frontX) * meleeDir;
        final inRange = dxFar >= 0 && dxNear < meleeRange;
        final vOverlap = playerBottom > child.position.y && playerTop < child.position.y + child.size.y;
        if (inRange && vOverlap) {
          child.hit(meleeDamage);
          final fx = child.position.x + child.size.x / 2;
          final fy = child.position.y + child.size.y / 2;
          gameRef.world.add(CollectEffect(pos: Vector2(fx, fy), color: pataponData.themeColor));
        }
      } else if (child is Boss && !child.isDead) {
        final bossLeft = child.position.x;
        final bossRight = child.position.x + child.size.x;
        final nearEdge = _facingRight ? bossLeft : bossRight;
        final farEdge = _facingRight ? bossRight : bossLeft;
        final dxNear = (nearEdge - frontX) * meleeDir;
        final dxFar = (farEdge - frontX) * meleeDir;
        final inRange = dxFar >= 0 && dxNear < meleeRange;
        final vOverlap = playerBottom > child.position.y && playerTop < child.position.y + child.size.y;
        if (inRange && vOverlap) {
          child.hit(meleeDamage);
          final fx = child.position.x + child.size.x / 2;
          final fy = child.position.y + child.size.y / 2;
          gameRef.world.add(CollectEffect(pos: Vector2(fx, fy), color: Colors.red));
        }
      }
    }
  }

  void _offhandAttack() {
    if (_offhandCooldown > 0 || lightnings <= 0) return;
    _offhandCooldown = 1.0;
    lightnings--;

    RetroSfx.instance.offhand();
    gameRef.screenFlashTimer = 0.1;

    final playerCenterX = position.x + size.x / 2;
    final playerCenterY = position.y + size.y / 2;

    switch (pataponData.id) {
      case 'drewniak':
        // Short local stun (was 10s → 4s)
        _applyDebuffToNearby(300, duration: 4, speedScale: 0.0, color: const Color(0xFF8B4513));
      case 'gaciar':
        // Turbo now also boosts melee reach so it has combat value (was 10s → 5s)
        _speedMultiplier = 2.0;
        _rangeMultiplier = 1.5;
        _powerUpTimer = 5;
        activePowerUpLabel = 'Turbo!';
      case 'grillak':
        for (int i = 0; i < 8; i++) {
          final angle = i * pi / 4;
          gameRef.world.add(Projectile(
            startPos: Vector2(playerCenterX, playerCenterY),
            direction: cos(angle),
            damage: 1,
            verticalSpeed: sin(angle) * 350,
          ));
        }
      case 'kundziak':
        // EMP: no longer whole-screen 10s lock. Big radius, short freeze (3s).
        _applyDebuffToNearby(600, duration: 3, speedScale: 0.0, color: const Color(0xFF00BFFF));
      case 'silny':
        // Real burn DoT (matches "podpala") instead of instant 2 dmg one-shot.
        _applyDebuffToNearby(250, duration: 4, speedScale: 0.5, color: const Color(0xFFFF4500));
        for (final child in gameRef.world.descendants()) {
          if (child is Enemy && !child.isDead) {
            final dx = (child.position.x + child.size.x / 2 - playerCenterX).abs();
            if (dx < 250) child.applyBurn(3.0);
          }
        }
      case 'tutek':
        // Slow by half (0.5, matches desc), big radius, 6s.
        _applyDebuffToNearby(400, duration: 6, speedScale: 0.5, color: const Color(0xFFDAA520));
      case 'wlosatol':
        for (final child in gameRef.world.descendants()) {
          if (child is Enemy && !child.isDead) {
            final dx = child.position.x + child.size.x / 2 - playerCenterX;
            if (dx.abs() < 300) {
              child.position.x += dx.sign * 200;
              child.hit(meleeDamage);
              child.applyDebuff(duration: 4, speedScale: 0.5, color: const Color(0xFFFF1493));
            }
          } else if (child is Boss && !child.isDead) {
            final dx = (child.position.x + child.size.x / 2 - playerCenterX).abs();
            if (dx < 300) {
              child.hit(meleeDamage);
              child.applyDebuff(duration: 2, speedScale: 0.5, color: const Color(0xFFFF1493));
            }
          }
        }
      case 'zieloniak':
        // Invulnerability (was 10s → 5s)
        shieldPowerUpTimer = 5;
      default:
        _applyDebuffToNearby(300, duration: 4, speedScale: 0.0, color: Colors.cyan);
    }

    gameRef.world.add(CollectEffect(pos: Vector2(playerCenterX, playerCenterY), color: const Color(0xFF00BFFF)));
  }

  void _applyDebuffToNearby(double range, {required double duration, required double speedScale, Color? color}) {
    final playerCenterX = position.x + size.x / 2;
    for (final child in gameRef.world.descendants()) {
      if (child is Enemy && !child.isDead) {
        final dx = (child.position.x + child.size.x / 2 - playerCenterX).abs();
        if (dx < range) {
          child.applyDebuff(duration: duration, speedScale: speedScale, color: color);
        }
      } else if (child is Boss && !child.isDead) {
        final dx = (child.position.x + child.size.x / 2 - playerCenterX).abs();
        if (dx < range) {
          child.applyDebuff(duration: duration, speedScale: speedScale, color: color);
        }
      }
    }
  }

  double _findNextPlatformX(double currentX) {
    double bestX = currentX + 100;
    double bestDist = double.infinity;
    // Platforms are children of the level, not of the world. Invisible blocks
    // are pit/arena walls, not ground to land on.
    for (final child in gameRef.level.children) {
      if (child is PlatformBlock && !child.invisible && child.size.y > 50) {
        final platLeft = child.position.x;
        final platRight = platLeft + child.size.x;
        if (platLeft > currentX && platLeft - currentX < bestDist) {
          bestDist = platLeft - currentX;
          bestX = platLeft + 40;
        }
        if (platLeft <= currentX && platRight > currentX) {
          bestX = currentX + 80;
          break;
        }
      }
    }
    return bestX;
  }

  void applyBurn(double duration) {
    _burnTimer = duration;
    _burnTick = 1.0;
  }

  // Matches the 4 steps per upgrade offered on the level-up screen.
  static const maxUpgradeLevel = 4;

  bool get _allUpgradesMaxed =>
      weaponLevel >= maxUpgradeLevel && speedLevel >= maxUpgradeLevel && jumpLevel >= maxUpgradeLevel;

  void _tryWeaponUpgrade(Vector2 coinCenter) {
    // With everything maxed the level-up screen would have no card to pick
    // and the game would stay paused for good.
    if (coins >= nextUpgradeCost && !_allUpgradesMaxed) {
      gameRef.showUpgradeChoice(coinCenter);
    }
  }

  void takeDamage(int damage) {
    if (gameRef.shieldMode) return;
    if (shieldPowerUpTimer > 0) return;
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

    final actualDamage = pataponData.id == 'drewniak' ? (damage * 0.5).ceil() : damage;

    hp -= actualDamage;
    _invincibleTimer = 1.0;
    RetroSfx.instance.hit();

    if (hp <= 0) {
      if (hasAngelProtection) {
        hasAngelProtection = false;
        hp = pataponData.maxHp;
        _invincibleTimer = 1.5;
        _burnTimer = 0;
      } else {
        hp = 0;
        (gameRef).onPlayerDied();
      }
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
        shieldPowerUpTimer = type.duration;
      case PowerUpType.bigWeapon:
        _rangeMultiplier = 2.0;
        _powerUpTimer = type.duration;
        activePowerUpLabel = type.label;
      case PowerUpType.heal:
        hp = (hp + 2).clamp(0, pataponData.maxHp);
      case PowerUpType.angelProtection:
        hasAngelProtection = true;
    }
  }

  void _drinkPotion(PotionType type) {
    final heal = type.heal;
    hp = heal == null ? pataponData.maxHp : (hp + heal).clamp(0, pataponData.maxHp);
    switch (type) {
      case PotionType.badziew:
        RetroSfx.instance.potionBadziew();
      case PotionType.spoko:
        RetroSfx.instance.potionSpoko();
      case PotionType.superowa:
        RetroSfx.instance.potionSuper();
    }
    gameRef.world.add(CollectEffect(pos: position + size / 2, color: type.color));
    gameRef.world.add(PotionPopup(type: type, pos: Vector2(position.x + size.x / 2, position.y - 6)));
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (other is PlatformBlock) {
      _handlePlatformCollision(other, intersectionPoints);
    } else if (_frozen) {
      return;
    } else if (other is Enemy && !other.isDead) {
      final playerBottom = position.y + size.y;
      final enemyTop = other.position.y;
      if (playerBottom - enemyTop < 15 && velocity.y > 0) {
        velocity.y = -250;
        other.stomp();
        RetroSfx.instance.stomp();
        gameRef.world.add(StompEffect(pos: other.position + other.size / 2));
      } else {
        takeDamage(other.damage);
      }
    } else if (other is PowerUpItem && !other.collected) {
      other.collect();
      collectPowerUp(other.type);
      RetroSfx.instance.powerUp();
      gameRef.world.add(CollectEffect(pos: other.position + other.size / 2, color: other.type.color));
      gameRef.showPowerUpToast('${other.type.icon} ${other.type.label}');
    } else if (other is Coin && !other.collected) {
      other.collect();
      coins++;
      RetroSfx.instance.coin();
      gameRef.world.add(CollectEffect(pos: other.position + other.size / 2, color: const Color(0xFFFFD700)));
      _tryWeaponUpgrade(other.position + other.size / 2);
    } else if (other is LightningPickup && !other.collected) {
      other.collect();
      lightnings++;
      RetroSfx.instance.coin();
      gameRef.world.add(CollectEffect(pos: other.position + other.size / 2, color: const Color(0xFF00BFFF)));
    } else if (other is Potion && other.canBePicked) {
      other.collect();
      _drinkPotion(other.type);
    } else if (other is FinishFlag) {
      (gameRef).onLevelComplete();
    } else if (other is Boss && !other.isDead) {
      takeDamage(1);
    } else if (other is BossPortal) {
      (gameRef).onLevelComplete();
    } else if (other is MysteryBox && !other.collected) {
      other.collect();
      applyScaleStep(other.scaleDirection);
      RetroSfx.instance.powerUp();
      gameRef.world.add(CollectEffect(pos: other.position + other.size / 2, color: Colors.white));
      final label = other.scaleDirection > 0 ? 'GROW!' : 'SHRINK!';
      gameRef.showPowerUpToast(label);
    } else if (other is BossArena && !other.triggered) {
      other.triggerBoss(this);
    }
  }

  void _handlePlatformCollision(PlatformBlock block, Set<Vector2> points) {
    if (points.length < 2) return;

    final mid = (points.first + points.last) / 2;
    final playerCenter = position + size / 2;
    final diff = mid - playerCenter;

    if (diff.y.abs() > diff.x.abs()) {
      if (diff.y < 0) {
        velocity.y = 0;
      } else {
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
    if (!_visible) return;
    if (_invincibleTimer > 0 && (_invincibleTimer * 10).toInt() % 2 == 0) return;

    final cx = size.x / 2;
    final cy = size.y / 2;

    // Gold flash effect
    if (_goldFlashTimer > 0 && (_goldFlashTimer * 5).toInt() % 2 == 0) {
      canvas.drawCircle(Offset(cx, cy), 28, Paint()..color = const Color(0xFFFFD700).withOpacity(0.3));
    }

    canvas.save();
    canvas.translate(cx, cy + 4);
    canvas.scale(1.0 / _squashStretch, _squashStretch);
    if (!_facingRight) canvas.scale(-1, 1);
    canvas.translate(-cx, -(cy + 4));

    final spritePaint = Paint()..filterQuality = FilterQuality.medium;
    final isAttacking = _swingTimer > 0;

    if (_bodyImage != null) {
      final isWalking = velocity.x.abs() > 10;

      if (_legsImage != null) {
        final bodyImgW = _bodyImage!.width.toDouble();
        final bodyImgH = _bodyImage!.height.toDouble();
        final legImgW = _legsImage!.width.toDouble();
        final legImgH = _legsImage!.height.toDouble();

        final scaleX = size.x / bodyImgW;
        final scaleY = size.y / bodyImgH;

        final double pivotX;
        final double pivotY;
        final double splitX;
        final double lpY;

        if (pataponData.legBodyX > 0) {
          pivotX = pataponData.legBodyX * scaleX;
          pivotY = pataponData.legBodyY * scaleY;
          splitX = pataponData.legPivotX;
          lpY = pataponData.legPivotY;
        } else {
          pivotX = size.x * pataponData.legX;
          pivotY = size.y * pataponData.legY;
          splitX = legImgW / 2;
          lpY = 0;
        }

        final rightSplitW = legImgW - splitX;
        final leftW = splitX * scaleX;
        final rightW = rightSplitW * scaleX;
        final legH = legImgH * scaleY;
        final pivotOffY = lpY * scaleY;

        final angleL = isWalking ? sin(_runPhase) * 0.16 : 0.0;
        final angleR = isWalking ? sin(_runPhase + pi) * 0.16 : 0.0;

        final srcL = Rect.fromLTWH(0, 0, splitX, legImgH);
        final srcR = Rect.fromLTWH(splitX, 0, rightSplitW, legImgH);

        canvas.save();
        canvas.translate(pivotX, pivotY);
        canvas.rotate(angleL);
        canvas.drawImageRect(_legsImage!, srcL,
            Rect.fromLTWH(-leftW, -pivotOffY, leftW, legH), spritePaint);
        canvas.restore();

        canvas.save();
        canvas.translate(pivotX, pivotY);
        canvas.rotate(angleR);
        canvas.drawImageRect(_legsImage!, srcR,
            Rect.fromLTWH(0, -pivotOffY, rightW, legH), spritePaint);
        canvas.restore();
      }

      final srcBody = Rect.fromLTWH(0, 0, _bodyImage!.width.toDouble(), _bodyImage!.height.toDouble());
      final dstBody = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.drawImageRect(_bodyImage!, srcBody, dstBody, spritePaint);
    } else {
      final bodyPaint = Paint()..color = pataponData.themeColor;
      canvas.drawCircle(Offset(cx, cy + 4), 18, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(cx, cy + 2), 11, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx + 3, cy + 2), 5, Paint()..color = Colors.black);
      canvas.drawRect(Rect.fromLTWH(cx - 12, 0, 24, 12), bodyPaint);
    }

    if (_weaponImage != null) {
      final wr = pataponData.weaponRegion;
      // Height drives the size; width follows the image's native aspect ratio
      // so the weapon sprite is never stretched horizontally.
      final weaponBaseH = size.y * wr.height * 1.8;
      final weaponBaseW = weaponBaseH * (_weaponImage!.width / _weaponImage!.height);

      if (isAttacking) {
        final swingProgress = 1.0 - (_swingTimer / _swingDuration);
        final swingAngle = -1.0 + swingProgress * 2.0;

        final atkScale = weaponMultiplier.clamp(1.0, 4.0);
        final weaponW = weaponBaseW * atkScale;
        final weaponH = weaponBaseH * atkScale;

        final pivotX = cx + 8;
        final pivotY = cy;

        canvas.save();
        canvas.translate(pivotX, pivotY);
        canvas.rotate(swingAngle);
        if (pataponData.id == 'gaciar') {
          canvas.scale(1, -1);
        }
        canvas.drawImageRect(
          _weaponImage!,
          Rect.fromLTWH(0, 0, _weaponImage!.width.toDouble(), _weaponImage!.height.toDouble()),
          Rect.fromLTWH(0, -weaponH / 2, weaponW, weaponH),
          spritePaint,
        );
        canvas.restore();
      } else {
        final weaponX = size.x * wr.left;
        final weaponY = size.y * wr.top;

        final walkBob = velocity.x.abs() > 10 ? sin(_runPhase) * 1.5 : 0.0;
        final breathBob = sin(_breathPhase) * 0.5;

        canvas.drawImageRect(
          _weaponImage!,
          Rect.fromLTWH(0, 0, _weaponImage!.width.toDouble(), _weaponImage!.height.toDouble()),
          Rect.fromLTWH(weaponX, weaponY + walkBob + breathBob, weaponBaseW, weaponBaseH),
          spritePaint,
        );
      }
    }

    canvas.restore();

    // Angel protection golden heart with glow & particles
    if (hasAngelProtection) {
      final heartY = -8.0 + sin(_breathPhase * 2) * 2;
      final hr = 6.0;

      // Outer glow pulses
      final glowPulse = 0.15 + sin(_breathPhase * 3) * 0.1;
      canvas.drawCircle(Offset(cx, heartY), 18, Paint()..color = Color.fromRGBO(255, 215, 0, glowPulse));
      canvas.drawCircle(Offset(cx, heartY), 12, Paint()..color = Color.fromRGBO(255, 215, 0, glowPulse + 0.1));

      // Sparkle particles orbiting the heart
      for (int i = 0; i < 5; i++) {
        final angle = _breathPhase * 2.5 + i * 1.257;
        final radius = 10.0 + sin(_breathPhase * 3 + i) * 3;
        final px = cx + cos(angle) * radius;
        final py = heartY + sin(angle) * radius * 0.6;
        final sparkleSize = 1.2 + sin(_breathPhase * 4 + i * 2) * 0.6;
        canvas.drawCircle(Offset(px, py), sparkleSize, Paint()..color = Color.fromRGBO(255, 255, 180, 0.7));
      }

      // Heart shape
      final heartPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(Offset(cx - hr * 0.5, heartY - hr * 0.3), hr * 0.55, heartPaint);
      canvas.drawCircle(Offset(cx + hr * 0.5, heartY - hr * 0.3), hr * 0.55, heartPaint);
      final path = ui.Path();
      path.moveTo(cx - hr, heartY);
      path.lineTo(cx, heartY + hr * 0.9);
      path.lineTo(cx + hr, heartY);
      path.close();
      canvas.drawPath(path, heartPaint);

      // Bright center highlight
      canvas.drawCircle(Offset(cx, heartY - hr * 0.1), hr * 0.25, Paint()..color = Color.fromRGBO(255, 255, 220, 0.6));
    }

    // Burn overlay
    if (_burnTimer > 0) {
      final burnPulse = (sin(_burnTimer * 8) * 0.15 + 0.3).clamp(0.15, 0.45);
      canvas.drawCircle(
        Offset(cx, cy + 4),
        20,
        Paint()..color = Colors.red.withOpacity(burnPulse),
      );
    }

    if (hasShield || gameRef.shieldMode || shieldPowerUpTimer > 0) {
      canvas.drawCircle(
        Offset(cx, cy + 4),
        22,
        Paint()..color = Colors.blue.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 3,
      );
    }
  }
}

class _PlayerFireParticle extends PositionComponent {
  double _life = 0;
  static const _maxLife = 0.4;
  static final _rng = Random();
  final double _drift;

  _PlayerFireParticle({required Vector2 pos})
      : _drift = (_rng.nextDouble() - 0.5) * 30 {
    position = pos;
    size = Vector2.all(1);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life += dt;
    position.y -= 40 * dt;
    position.x += _drift * dt;
    if (_life > _maxLife) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = _life / _maxLife;
    final r = 2.5 + (1.0 - progress) * 3;
    final opacity = (1.0 - progress) * 0.7;
    final color = Color.lerp(Colors.yellow, Colors.red, progress)!;
    canvas.drawCircle(Offset.zero, r, Paint()..color = color.withOpacity(opacity));
  }
}
