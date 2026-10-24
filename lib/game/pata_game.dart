import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/patapon_data.dart';
import 'audio/retro_sfx.dart';
import 'audio/retro_music.dart';
import 'components/player.dart';
import 'components/background.dart';
import 'components/boss_arena.dart';
import 'components/boss_spawn_effect.dart';
import 'levels/level.dart';

class CharacterUpgrades {
  int weaponLevel;
  int speedLevel;
  int jumpLevel;
  int scaleStep;
  CharacterUpgrades({this.weaponLevel = 0, this.speedLevel = 0, this.jumpLevel = 0, this.scaleStep = 0});
}

class GameState {
  final int hp;
  final int maxHp;
  final int ammo;
  final bool hasShield;
  final double shieldTimer;
  final String? activePowerUp;
  final int coins;
  final bool shieldMode;
  final int currentLevel;
  final int lightnings;
  final int weaponLevel;
  final double weaponMultiplier;
  final int nextUpgradeCost;
  final double screenFlash;
  final int speedLevel;
  final int jumpLevel;
  final String? powerUpToast;

  const GameState({
    this.hp = 4,
    this.maxHp = 4,
    this.ammo = 0,
    this.hasShield = false,
    this.shieldTimer = 0,
    this.activePowerUp,
    this.coins = 0,
    this.shieldMode = false,
    this.currentLevel = 1,
    this.lightnings = 0,
    this.weaponLevel = 0,
    this.weaponMultiplier = 1.0,
    this.nextUpgradeCost = 10,
    this.screenFlash = 0,
    this.speedLevel = 0,
    this.jumpLevel = 0,
    this.powerUpToast,
  });

  // Value equality: ValueNotifier only notifies when the value changes, so the
  // HUD is rebuilt when something on it changes instead of on every frame.
  @override
  bool operator ==(Object other) =>
      other is GameState &&
      other.hp == hp &&
      other.maxHp == maxHp &&
      other.ammo == ammo &&
      other.hasShield == hasShield &&
      other.shieldTimer == shieldTimer &&
      other.activePowerUp == activePowerUp &&
      other.coins == coins &&
      other.shieldMode == shieldMode &&
      other.currentLevel == currentLevel &&
      other.lightnings == lightnings &&
      other.weaponLevel == weaponLevel &&
      other.weaponMultiplier == weaponMultiplier &&
      other.nextUpgradeCost == nextUpgradeCost &&
      other.screenFlash == screenFlash &&
      other.speedLevel == speedLevel &&
      other.jumpLevel == jumpLevel &&
      other.powerUpToast == powerUpToast;

  @override
  int get hashCode => Object.hash(
        hp, maxHp, ammo, hasShield, shieldTimer, activePowerUp, coins,
        shieldMode, currentLevel, lightnings, weaponLevel, weaponMultiplier,
        nextUpgradeCost, screenFlash, speedLevel, jumpLevel, powerUpToast,
      );
}

class PataGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  PataponData pataponData;
  final bool shieldMode;
  late Player player;
  late GameLevel level;
  final ValueNotifier<GameState> stateNotifier = ValueNotifier(const GameState());

  bool levelComplete = false;
  bool gameOver = false;
  int currentLevel;

  double screenFlashTimer = 0;

  // Per-character upgrade storage
  final Map<String, CharacterUpgrades> _characterUpgrades = {};

  // Power-up toast
  String? _powerUpToast;
  double _powerUpToastTimer = 0;

  PataGame({required this.pataponData, this.shieldMode = false, this.currentLevel = 1});

  CharacterUpgrades _getUpgrades(String charId) {
    return _characterUpgrades.putIfAbsent(charId, () => CharacterUpgrades());
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    pauseEngine();

    await RetroSfx.instance.init();
    await RetroMusic.instance.init();

    // Clean any leftover state from previous sessions
    for (final child in world.children.toList()) {
      child.removeFromParent();
    }
    await Future<void>.delayed(Duration.zero);

    camera.viewfinder.anchor = Anchor.topLeft;

    level = GameLevel(levelNumber: currentLevel);
    await world.add(level);

    final ups = _getUpgrades(pataponData.id);
    player = Player(
      pataponData: pataponData,
      shieldMode: shieldMode,
      persistWeaponLevel: ups.weaponLevel,
      persistSpeedLevel: ups.speedLevel,
      persistJumpLevel: ups.jumpLevel,
      persistScaleStep: ups.scaleStep,
    );
    await world.add(player);

    // Let all components finish loading before unpausing
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    RetroMusic.instance.playLevel(currentLevel);

    _updateState();
    resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver || levelComplete || transitioning || bossIntroActive) return;

    if (screenFlashTimer > 0) screenFlashTimer -= dt;

    if (_powerUpToastTimer > 0) {
      _powerUpToastTimer -= dt;
      if (_powerUpToastTimer <= 0) _powerUpToast = null;
    }

    _updateCamera();
    _updateState();
  }

  void _updateCamera() {
    final screenWidth = size.x;
    final screenHeight = size.y;
    final cameraX = (player.position.x - screenWidth * 0.35).clamp(0.0, double.infinity);
    final cameraY = (player.position.y - screenHeight * 0.5).clamp(0.0, double.infinity);
    camera.viewfinder.position = Vector2(cameraX, cameraY);
  }

  void showPowerUpToast(String text) {
    _powerUpToast = text;
    _powerUpToastTimer = 2.0;
  }

  void _updateState() {
    stateNotifier.value = GameState(
      hp: player.hp,
      maxHp: pataponData.maxHp,
      ammo: player.ammo,
      hasShield: player.hasShield,
      shieldTimer: player.shieldPowerUpTimer,
      activePowerUp: player.activePowerUpLabel,
      coins: player.coins,
      shieldMode: shieldMode,
      currentLevel: currentLevel,
      lightnings: player.lightnings,
      weaponLevel: player.weaponLevel,
      weaponMultiplier: player.weaponMultiplier,
      nextUpgradeCost: player.nextUpgradeCost,
      screenFlash: screenFlashTimer,
      speedLevel: player.speedLevel,
      jumpLevel: player.jumpLevel,
      powerUpToast: _powerUpToast,
    );
  }

  void _saveCurrentUpgrades() {
    final ups = _getUpgrades(pataponData.id);
    ups.weaponLevel = player.weaponLevel;
    ups.speedLevel = player.speedLevel;
    ups.jumpLevel = player.jumpLevel;
    ups.scaleStep = player.scaleStep;
  }

  void onPlayerDied() {
    // Collisions keep firing after death; dying twice must not drop two levels.
    if (gameOver || levelComplete) return;
    if (currentLevel > 1) {
      currentLevel--;
    }
    gameOver = true;
    RetroSfx.instance.death();
    overlays.add('GameOver');
  }

  void onLevelComplete() {
    if (levelComplete) return;
    levelComplete = true;
    player.freeze();
    _saveCurrentUpgrades();
    RetroSfx.instance.levelComplete();
    if (currentLevel < 10) {
      overlays.add('LevelComplete');
    } else {
      overlays.add('GameWon');
    }
  }

  bool transitioning = false;

  Vector2 _cameraForSpawn(Vector2 spawn) => Vector2(
    (spawn.x - size.x * 0.35).clamp(0.0, double.infinity),
    (spawn.y - size.y * 0.5).clamp(0.0, double.infinity),
  );

  Future<void> _loadLevel() async {
    if (transitioning) return;
    transitioning = true;
    pauseEngine();
    _saveCurrentUpgrades();

    final oldCoins = player.coins;
    final oldLightnings = player.lightnings;
    final oldAngelProtection = player.hasAngelProtection;

    final spawnPos = Vector2(100, 436);
    camera.viewfinder.position = _cameraForSpawn(spawnPos);

    // Aggressively remove everything — including descendants added to world directly
    for (final child in world.children.toList()) {
      child.removeFromParent();
    }
    resumeEngine();
    await Future<void>.delayed(Duration.zero);
    pauseEngine();
    for (final child in world.children.toList()) {
      child.removeFromParent();
    }
    resumeEngine();
    await Future<void>.delayed(Duration.zero);
    pauseEngine();
    // Third pass — catch stragglers from mid-loading components
    for (final child in world.children.toList()) {
      child.removeFromParent();
    }

    screenFlashTimer = 0;
    _powerUpToast = null;
    _powerUpToastTimer = 0;

    // Dying during the boss intro must not leave it running into the new level.
    overlays.remove('BossIntro');
    bossIntroActive = false;
    currentBossArena = null;

    _updateState();
    resumeEngine();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    pauseEngine();

    level = GameLevel(levelNumber: currentLevel);
    await world.add(level);

    final ups = _getUpgrades(pataponData.id);
    player = Player(
      pataponData: pataponData,
      shieldMode: shieldMode,
      persistCoins: oldCoins,
      persistLightnings: oldLightnings,
      persistWeaponLevel: ups.weaponLevel,
      persistSpeedLevel: ups.speedLevel,
      persistJumpLevel: ups.jumpLevel,
      persistScaleStep: ups.scaleStep,
      persistAngelProtection: oldAngelProtection,
    );
    // Position is left unset so Player.onLoad puts the feet on the ground for
    // its actual (possibly grown/shrunk) size, same as on the first load.
    await world.add(player);

    // Let all components finish loading
    resumeEngine();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    camera.viewfinder.position = _cameraForSpawn(player.position);

    RetroMusic.instance.playLevel(currentLevel);
    _updateState();
    transitioning = false;
  }

  void nextLevel() {
    if (currentLevel < 10) currentLevel++;
    levelComplete = false;
    overlays.remove('LevelComplete');
    _loadLevel();
  }

  void restartLevel() {
    gameOver = false;
    levelComplete = false;
    overlays.remove('GameOver');
    overlays.remove('LevelComplete');
    overlays.remove('GameWon');
    _loadLevel();
  }

  void switchCharacter(PataponData newData) {
    _saveCurrentUpgrades();

    final oldCoins = player.coins;
    final oldLightnings = player.lightnings;
    final oldPos = player.position.clone();
    final oldAngelProtection = player.hasAngelProtection;

    pataponData = newData;
    final ups = _getUpgrades(newData.id);

    world.remove(player);
    player = Player(
      pataponData: newData,
      shieldMode: shieldMode,
      persistCoins: oldCoins,
      persistLightnings: oldLightnings,
      persistWeaponLevel: ups.weaponLevel,
      persistSpeedLevel: ups.speedLevel,
      persistJumpLevel: ups.jumpLevel,
      persistScaleStep: ups.scaleStep,
      persistAngelProtection: oldAngelProtection,
    );
    player.position = oldPos;
    world.add(player);

    screenFlashTimer = 0.15;
    RetroSfx.instance.switchHero();
  }

  bool bossIntroActive = false;
  BossArena? currentBossArena;
  String bossIntroName = '';

  Future<void> startBossIntro(BossArena arena) async {
    if (bossIntroActive) return;
    bossIntroActive = true;
    currentBossArena = arena;
    bossIntroName = 'BOSS!';
    player.freeze();

    // Switch to boss music
    RetroMusic.instance.playBoss();

    // Show boss intro overlay (black screen + name flash)
    overlays.add('BossIntro');

    // After overlay handles its animation, it calls finishBossIntro()
  }

  void finishBossIntro() {
    if (!bossIntroActive) return;
    overlays.remove('BossIntro');
    currentBossArena?.spawnBoss();
    bossIntroActive = false;
    player.unfreeze();
    screenFlashTimer = 0.5;
    RetroSfx.instance.bossRoar();

    // Massive spawn effects
    final boss = currentBossArena?.boss;
    if (boss != null) {
      final cx = boss.position.x + boss.size.x / 2;
      final cy = boss.position.y + boss.size.y / 2;
      world.add(BossSpawnEffect(pos: Vector2(cx, cy)));
    }
  }

  void showUpgradeChoice() {
    paused = true;
    overlays.add('UpgradeChoice');
  }

  void applyUpgrade(String type) {
    overlays.remove('UpgradeChoice');
    paused = false;

    player.coins -= player.nextUpgradeCost;

    switch (type) {
      case 'weapon':
        player.weaponLevel++;
        player.recalcWeapon();
      case 'speed':
        player.speedLevel++;
        player.recalcSpeed();
      case 'jump':
        player.jumpLevel++;
        player.recalcJump();
    }

    _saveCurrentUpgrades();
    screenFlashTimer = 0.2;
    RetroSfx.instance.upgradeCheer();
    _updateState();
  }
}
