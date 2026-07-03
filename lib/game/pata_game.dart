import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/patapon_data.dart';
import 'components/player.dart';
import 'components/background.dart';
import 'levels/level.dart';

class GameState {
  final int hp;
  final int maxHp;
  final int ammo;
  final bool hasShield;
  final String? activePowerUp;
  final int coins;

  const GameState({
    this.hp = 4,
    this.maxHp = 4,
    this.ammo = 0,
    this.hasShield = false,
    this.activePowerUp,
    this.coins = 0,
  });
}

class PataGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  final PataponData pataponData;
  late Player player;
  late GameLevel level;
  final ValueNotifier<GameState> stateNotifier = ValueNotifier(const GameState());

  bool levelComplete = false;
  bool gameOver = false;

  PataGame({required this.pataponData});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    level = GameLevel(levelNumber: 1);
    await world.add(level);

    player = Player(pataponData: pataponData);
    await world.add(player);

    _updateState();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameOver || levelComplete) return;

    _updateCamera();
    _updateState();
  }

  void _updateCamera() {
    final screenWidth = size.x;
    final cameraX = (player.position.x - screenWidth * 0.35).clamp(0.0, double.infinity);
    camera.viewfinder.position = Vector2(cameraX, 0);
  }

  void _updateState() {
    stateNotifier.value = GameState(
      hp: player.hp,
      maxHp: pataponData.maxHp,
      ammo: player.ammo,
      hasShield: player.hasShield,
      activePowerUp: player.activePowerUpLabel,
      coins: player.coins,
    );
  }

  void onPlayerDied() {
    gameOver = true;
    overlays.add('GameOver');
  }

  void onLevelComplete() {
    levelComplete = true;
    overlays.add('LevelComplete');
  }

  void restartLevel() {
    gameOver = false;
    levelComplete = false;
    overlays.remove('GameOver');
    overlays.remove('LevelComplete');
    world.removeAll(world.children);

    level = GameLevel(levelNumber: 1);
    world.add(level);
    player = Player(pataponData: pataponData);
    world.add(player);
  }
}
