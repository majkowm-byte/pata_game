import 'package:flame/components.dart';
import '../../models/powerup_type.dart';
import '../components/background.dart';
import '../components/coin.dart';
import '../components/enemy.dart';
import '../components/finish_flag.dart';
import '../components/platform_block.dart';
import '../components/powerup_item.dart';

class GameLevel extends Component {
  final int levelNumber;

  GameLevel({required this.levelNumber});

  @override
  Future<void> onLoad() async {
    add(Background());
    _buildLevel1();
  }

  void _buildLevel1() {
    // Ground
    _addPlatform(0, 500, 800, 100);
    _addPlatform(900, 500, 400, 100);
    _addPlatform(1400, 500, 300, 100);
    _addPlatform(1800, 500, 600, 100);
    _addPlatform(2500, 500, 400, 100);
    _addPlatform(3000, 500, 800, 100);

    // Floating platforms
    _addPlatform(300, 380, 120, 20);
    _addPlatform(500, 300, 120, 20);
    _addPlatform(700, 350, 100, 20);

    _addPlatform(950, 380, 100, 20);
    _addPlatform(1100, 300, 100, 20);

    _addPlatform(1500, 380, 80, 20);
    _addPlatform(1650, 320, 100, 20);

    _addPlatform(2000, 380, 120, 20);
    _addPlatform(2200, 300, 100, 20);
    _addPlatform(2350, 350, 80, 20);

    _addPlatform(2600, 380, 100, 20);
    _addPlatform(2800, 300, 120, 20);

    _addPlatform(3100, 380, 100, 20);
    _addPlatform(3300, 300, 120, 20);
    _addPlatform(3500, 250, 100, 20);

    // Enemies
    add(Enemy(pos: Vector2(400, 464), patrolSpeed: 50, patrolRange: 80));
    add(Enemy(pos: Vector2(1000, 464), patrolSpeed: 60, patrolRange: 100));
    add(Enemy(pos: Vector2(1550, 464), patrolSpeed: 70, patrolRange: 60));
    add(Enemy(pos: Vector2(2000, 464), patrolSpeed: 55, patrolRange: 120));
    add(Enemy(pos: Vector2(2100, 464), patrolSpeed: 65, patrolRange: 80));
    add(Enemy(pos: Vector2(2600, 464), patrolSpeed: 80, patrolRange: 100));
    add(Enemy(pos: Vector2(3200, 464), patrolSpeed: 70, patrolRange: 150, hp: 2));
    add(Enemy(pos: Vector2(3500, 464), patrolSpeed: 90, patrolRange: 100, hp: 2));

    // Platform enemies
    add(Enemy(pos: Vector2(520, 264), patrolSpeed: 30, patrolRange: 40));
    add(Enemy(pos: Vector2(2220, 264), patrolSpeed: 35, patrolRange: 40));

    // Coins
    _addCoinRow(150, 470, 5);
    _addCoinRow(350, 350, 3);
    _addCoinRow(950, 350, 3);
    _addCoinRow(1450, 470, 4);
    _addCoinRow(1850, 470, 5);
    _addCoinRow(2050, 350, 3);
    _addCoinRow(2550, 470, 4);
    _addCoinRow(3050, 470, 5);
    _addCoinRow(3350, 270, 3);

    // Power-ups
    add(PowerUpItem(pos: Vector2(530, 270), type: PowerUpType.extraAmmo));
    add(PowerUpItem(pos: Vector2(1120, 270), type: PowerUpType.speedBoost));
    add(PowerUpItem(pos: Vector2(1670, 290), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(2220, 270), type: PowerUpType.bigWeapon));
    add(PowerUpItem(pos: Vector2(2820, 270), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(3520, 220), type: PowerUpType.extraAmmo));

    // Finish flag
    add(FinishFlag(pos: Vector2(3700, 420)));
  }

  void _addPlatform(double x, double y, double w, double h) {
    add(PlatformBlock(pos: Vector2(x, y), blockSize: Vector2(w, h)));
  }

  void _addCoinRow(double startX, double y, int count) {
    for (int i = 0; i < count; i++) {
      add(Coin(pos: Vector2(startX + i * 30, y)));
    }
  }
}
