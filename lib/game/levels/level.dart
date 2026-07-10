import 'package:flame/components.dart';
import '../../models/powerup_type.dart';
import '../components/background.dart';
import '../components/boss_arena.dart';
import '../components/coin.dart';
import '../components/enemy.dart';
import '../components/mighty_eagle.dart';
import '../components/platform_block.dart';
import '../components/powerup_item.dart';

class GameLevel extends Component {
  final int levelNumber;

  GameLevel({required this.levelNumber});

  static const List<LevelTheme> themes = [
    LevelTheme.meadow,   // 1
    LevelTheme.forest,   // 2
    LevelTheme.jungle,   // 3
    LevelTheme.desert,   // 4
    LevelTheme.meadow,   // 5
    LevelTheme.space,    // 6
    LevelTheme.forest,   // 7
    LevelTheme.desert,   // 8
    LevelTheme.jungle,   // 9
    LevelTheme.lava,     // 10
  ];

  static const List<String> levelNames = [
    'Słoneczna Łąka',
    'Zielony Las',
    'Gęsta Dżungla',
    'Gorąca Pustynia',
    'Magiczna Łąka',
    'Mroczny Kosmos',
    'Jesienny Las',
    'Pustynna Noc',
    'Szmaragdowa Dżungla',
    'Ognista Lawa',
  ];

  static String nameFor(int level) => levelNames[(level - 1).clamp(0, levelNames.length - 1)];

  late LevelTheme _theme;

  @override
  Future<void> onLoad() async {
    final themeIndex = (levelNumber - 1).clamp(0, themes.length - 1);
    _theme = themes[themeIndex];
    add(Background(theme: _theme, worldWidth: 12000));

    switch (levelNumber) {
      case 1: _buildLevel1();
      case 2: _buildLevel2();
      case 3: _buildLevel3();
      case 4: _buildLevel4();
      case 5: _buildLevel5();
      case 6: _buildLevel6();
      case 7: _buildLevel7();
      case 8: _buildLevel8();
      case 9: _buildLevel9();
      case 10: _buildLevel10();
      default: _buildLevel1();
    }
    _addPitWalls();
    _spawnEagle();
  }

  static const List<double> _arenaXByLevel = [
    5300, 5900, 5850, 5900, 6150, 6600, 6900, 7700, 7800, 8800,
  ];

  void _spawnEagle() {
    final arenaX = _arenaXByLevel[(levelNumber - 1).clamp(0, 9)];
    final triggerX = arenaX * 0.5;
    add(MightyEagle(triggerX: triggerX));
  }

  void _buildLevel1() {
    // Ground — small gaps (gap ~80)
    _addPlatform(0, 500, 1100, 100);
    _addPlatform(1180, 500, 1000, 100);
    _addPlatform(2260, 500, 900, 100);
    _addPlatform(3240, 500, 1100, 100);
    _addPlatform(4420, 500, 1000, 100);

    // Tier 1
    _addPlatform(300, 400, 140, 20);
    _addPlatform(700, 390, 120, 20);
    _addPlatform(1100, 400, 120, 20);
    _addPlatform(1500, 380, 140, 20);
    _addPlatform(2000, 400, 120, 20);
    _addPlatform(2600, 390, 140, 20);
    _addPlatform(3100, 380, 120, 20);
    _addPlatform(3600, 400, 140, 20);
    _addPlatform(4100, 390, 120, 20);
    _addPlatform(4600, 380, 120, 20);
    _addPlatform(4900, 400, 120, 20);
    _addPlatform(5200, 390, 120, 20);
    // Tier 2
    _addPlatform(500, 290, 120, 20);
    _addPlatform(1300, 280, 120, 20);
    _addPlatform(2400, 290, 120, 20);
    _addPlatform(3400, 280, 120, 20);
    _addPlatform(4400, 270, 120, 20);
    _addPlatform(4800, 280, 120, 20);
    // Tier 3
    _addPlatform(900, 200, 100, 20);
    _addPlatform(2100, 190, 120, 20);
    _addPlatform(3800, 200, 100, 20);
    _addPlatform(4700, 200, 100, 20);

    add(Enemy(pos: Vector2(500, 464), patrolSpeed: 40, patrolRange: 80));
    add(Enemy(pos: Vector2(1400, 464), patrolSpeed: 45, patrolRange: 90));
    add(Enemy(pos: Vector2(2500, 464), patrolSpeed: 45, patrolRange: 80));
    add(Enemy(pos: Vector2(3500, 464), patrolSpeed: 50, patrolRange: 70));
    add(Enemy(pos: Vector2(4500, 464), patrolSpeed: 50, patrolRange: 80));
    add(Enemy(pos: Vector2(5000, 464), patrolSpeed: 45, patrolRange: 70));

    _addCoinRow(150, 470, 6);
    _addCoinRow(400, 370, 4);
    _addCoinRow(1300, 470, 5);
    _addCoinRow(2000, 370, 4);
    _addCoinRow(2700, 470, 6);
    _addCoinRow(3500, 470, 5);
    _addCoinRow(4200, 360, 4);
    _addCoinRow(4700, 470, 5);
    _addCoinRow(5100, 360, 3);

    add(PowerUpItem(pos: Vector2(550, 260), type: PowerUpType.extraAmmo));
    add(PowerUpItem(pos: Vector2(2150, 160), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(3850, 170), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:5300));
  }

  void _buildLevel2() {
    // Gaps ~80
    _addPlatform(0, 500, 1000, 100);
    _addPlatform(1080, 500, 900, 100);
    _addPlatform(2060, 500, 1000, 100);
    _addPlatform(3140, 500, 900, 100);
    _addPlatform(4120, 500, 1000, 100);
    _addPlatform(5200, 500, 800, 100);

    // Tier 1
    _addPlatform(300, 400, 120, 20);
    _addPlatform(700, 380, 140, 20);
    _addPlatform(1200, 390, 120, 20);
    _addPlatform(1700, 370, 120, 20);
    _addPlatform(2300, 400, 140, 20);
    _addPlatform(2800, 380, 120, 20);
    _addPlatform(3400, 390, 140, 20);
    _addPlatform(3900, 380, 120, 20);
    _addPlatform(4400, 400, 120, 20);
    _addPlatform(4900, 370, 140, 20);
    _addPlatform(5400, 390, 120, 20);
    _addPlatform(5700, 380, 120, 20);
    // Tier 2
    _addPlatform(500, 280, 120, 20);
    _addPlatform(1500, 270, 140, 20);
    _addPlatform(2600, 280, 120, 20);
    _addPlatform(3700, 270, 120, 20);
    _addPlatform(5100, 280, 120, 20);
    _addPlatform(5500, 270, 120, 20);
    // Tier 3
    _addPlatform(900, 200, 120, 20);
    _addPlatform(2100, 190, 120, 20);
    _addPlatform(4200, 200, 100, 20);
    _addPlatform(5300, 200, 100, 20);

    add(Enemy(pos: Vector2(400, 464), patrolSpeed: 45, patrolRange: 80));
    add(Enemy(pos: Vector2(1300, 464), patrolSpeed: 50, patrolRange: 80));
    add(Enemy(pos: Vector2(2400, 464), patrolSpeed: 55, patrolRange: 70));
    add(Enemy(pos: Vector2(3300, 464), patrolSpeed: 50, patrolRange: 90));
    add(Enemy(pos: Vector2(4300, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(5300, 464), patrolSpeed: 50, patrolRange: 70));
    add(Enemy(pos: Vector2(5700, 464), patrolSpeed: 50, patrolRange: 70));
    add(Enemy(pos: Vector2(1550, 244), patrolSpeed: 30, patrolRange: 50));

    _addCoinRow(150, 470, 5);
    _addCoinRow(450, 370, 4);
    _addCoinRow(1200, 470, 6);
    _addCoinRow(1750, 340, 4);
    _addCoinRow(2500, 470, 5);
    _addCoinRow(3200, 370, 4);
    _addCoinRow(4000, 470, 6);
    _addCoinRow(4950, 340, 4);
    _addCoinRow(5400, 470, 5);

    add(PowerUpItem(pos: Vector2(940, 170), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(2650, 250), type: PowerUpType.speedBoost));
    add(PowerUpItem(pos: Vector2(4250, 170), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:5900));
  }

  void _buildLevel3() {
    // Gaps ~90
    _addPlatform(0, 500, 900, 100);
    _addPlatform(990, 500, 900, 100);
    _addPlatform(1980, 500, 800, 100);
    _addPlatform(2870, 500, 1000, 100);
    _addPlatform(3960, 500, 900, 100);
    _addPlatform(4950, 500, 1000, 100);

    // Tier 1
    _addPlatform(300, 400, 120, 20);
    _addPlatform(650, 370, 140, 20);
    _addPlatform(1100, 390, 120, 20);
    _addPlatform(1600, 380, 120, 20);
    _addPlatform(2100, 400, 140, 20);
    _addPlatform(2600, 370, 120, 20);
    _addPlatform(3100, 390, 140, 20);
    _addPlatform(3600, 380, 120, 20);
    _addPlatform(4200, 400, 120, 20);
    _addPlatform(4700, 370, 140, 20);
    _addPlatform(5200, 390, 120, 20);
    _addPlatform(5600, 380, 120, 20);
    // Tier 2
    _addPlatform(450, 280, 120, 20);
    _addPlatform(1350, 270, 140, 20);
    _addPlatform(2400, 280, 120, 20);
    _addPlatform(3400, 260, 120, 20);
    _addPlatform(4500, 270, 140, 20);
    // Tier 3
    _addPlatform(800, 190, 120, 20);
    _addPlatform(2000, 200, 120, 20);
    _addPlatform(3900, 190, 100, 20);
    _addPlatform(5400, 200, 120, 20);

    add(Enemy(pos: Vector2(400, 464), patrolSpeed: 50, patrolRange: 90));
    add(Enemy(pos: Vector2(1200, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(2200, 464), patrolSpeed: 50, patrolRange: 90));
    add(Enemy(pos: Vector2(3200, 464), patrolSpeed: 60, patrolRange: 80));
    add(Enemy(pos: Vector2(4300, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(5300, 464), patrolSpeed: 55, patrolRange: 70));
    add(Enemy(pos: Vector2(1400, 244), patrolSpeed: 30, patrolRange: 50));
    add(Enemy(pos: Vector2(3450, 234), patrolSpeed: 35, patrolRange: 40));

    _addCoinRow(100, 470, 5);
    _addCoinRow(500, 340, 4);
    _addCoinRow(1100, 470, 6);
    _addCoinRow(1650, 350, 4);
    _addCoinRow(2500, 470, 5);
    _addCoinRow(3300, 360, 4);
    _addCoinRow(4100, 470, 6);
    _addCoinRow(4750, 340, 4);
    _addCoinRow(5300, 470, 5);

    add(PowerUpItem(pos: Vector2(850, 160), type: PowerUpType.bigWeapon));
    add(PowerUpItem(pos: Vector2(2450, 250), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(3950, 160), type: PowerUpType.angelProtection));
    add(PowerUpItem(pos: Vector2(5450, 170), type: PowerUpType.shield));

    add(BossArena(theme: _theme, arenaX:5850));
  }

  void _buildLevel4() {
    // Gaps ~100
    _addPlatform(0, 500, 1000, 100);
    _addPlatform(1100, 500, 800, 100);
    _addPlatform(2000, 500, 1000, 100);
    _addPlatform(3100, 500, 800, 100);
    _addPlatform(4000, 500, 1000, 100);
    _addPlatform(5100, 500, 900, 100);

    // Tier 1
    _addPlatform(350, 400, 140, 20);
    _addPlatform(800, 370, 120, 20);
    _addPlatform(1300, 390, 140, 20);
    _addPlatform(1800, 360, 120, 20);
    _addPlatform(2400, 400, 140, 20);
    _addPlatform(2900, 380, 120, 20);
    _addPlatform(3400, 370, 140, 20);
    _addPlatform(3900, 390, 120, 20);
    _addPlatform(4400, 380, 140, 20);
    _addPlatform(4900, 370, 120, 20);
    _addPlatform(5400, 390, 120, 20);
    _addPlatform(5700, 380, 120, 20);
    // Tier 2
    _addPlatform(550, 280, 120, 20);
    _addPlatform(1550, 270, 140, 20);
    _addPlatform(2700, 260, 120, 20);
    _addPlatform(3700, 280, 120, 20);
    _addPlatform(5100, 270, 140, 20);
    _addPlatform(5500, 260, 120, 20);
    // Tier 3
    _addPlatform(1000, 200, 120, 20);
    _addPlatform(2200, 190, 120, 20);
    _addPlatform(4200, 200, 120, 20);
    _addPlatform(5300, 200, 100, 20);

    add(Enemy(pos: Vector2(500, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(1400, 464), patrolSpeed: 50, patrolRange: 80));
    add(Enemy(pos: Vector2(2400, 464), patrolSpeed: 60, patrolRange: 80));
    add(Enemy(pos: Vector2(3300, 464), patrolSpeed: 55, patrolRange: 90));
    add(Enemy(pos: Vector2(4300, 464), patrolSpeed: 65, patrolRange: 70));
    add(Enemy(pos: Vector2(5300, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(5700, 464), patrolSpeed: 55, patrolRange: 70));
    add(Enemy(pos: Vector2(1600, 244), patrolSpeed: 35, patrolRange: 50));
    add(Enemy(pos: Vector2(3750, 254), patrolSpeed: 30, patrolRange: 40));

    _addCoinRow(150, 470, 6);
    _addCoinRow(600, 340, 4);
    _addCoinRow(1300, 470, 5);
    _addCoinRow(2200, 370, 4);
    _addCoinRow(3000, 470, 6);
    _addCoinRow(3800, 360, 4);
    _addCoinRow(4500, 470, 5);
    _addCoinRow(5200, 340, 4);

    add(PowerUpItem(pos: Vector2(600, 250), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(1050, 170), type: PowerUpType.extraAmmo));
    add(PowerUpItem(pos: Vector2(2750, 230), type: PowerUpType.speedBoost));
    add(PowerUpItem(pos: Vector2(4250, 170), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:5900));
  }

  void _buildLevel5() {
    // Gaps ~110
    _addPlatform(0, 500, 1100, 100);
    _addPlatform(1210, 500, 900, 100);
    _addPlatform(2220, 500, 800, 100);
    _addPlatform(3130, 500, 1000, 100);
    _addPlatform(4240, 500, 800, 100);
    _addPlatform(5150, 500, 1100, 100);

    // Tier 1
    _addPlatform(400, 400, 140, 20);
    _addPlatform(850, 380, 120, 20);
    _addPlatform(1400, 390, 140, 20);
    _addPlatform(1900, 370, 120, 20);
    _addPlatform(2500, 400, 140, 20);
    _addPlatform(3000, 380, 120, 20);
    _addPlatform(3500, 370, 140, 20);
    _addPlatform(4000, 390, 120, 20);
    _addPlatform(4500, 380, 120, 20);
    _addPlatform(5000, 400, 140, 20);
    _addPlatform(5500, 370, 120, 20);
    _addPlatform(5900, 390, 120, 20);
    // Tier 2
    _addPlatform(600, 280, 140, 20);
    _addPlatform(1650, 270, 120, 20);
    _addPlatform(2800, 280, 140, 20);
    _addPlatform(3800, 270, 120, 20);
    _addPlatform(5300, 260, 140, 20);
    // Tier 3
    _addPlatform(1100, 190, 120, 20);
    _addPlatform(2300, 200, 120, 20);
    _addPlatform(4300, 190, 120, 20);
    _addPlatform(5700, 200, 100, 20);

    add(Enemy(pos: Vector2(600, 464), patrolSpeed: 50, patrolRange: 90));
    add(Enemy(pos: Vector2(1500, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(2600, 464), patrolSpeed: 60, patrolRange: 90));
    add(Enemy(pos: Vector2(3400, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(4500, 464), patrolSpeed: 65, patrolRange: 70));
    add(Enemy(pos: Vector2(5500, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(5900, 464), patrolSpeed: 60, patrolRange: 70));
    add(Enemy(pos: Vector2(900, 354), patrolSpeed: 30, patrolRange: 50));
    add(Enemy(pos: Vector2(3850, 244), patrolSpeed: 35, patrolRange: 40));

    _addCoinRow(200, 470, 6);
    _addCoinRow(650, 350, 4);
    _addCoinRow(1400, 470, 5);
    _addCoinRow(2000, 340, 4);
    _addCoinRow(2800, 470, 6);
    _addCoinRow(3600, 340, 4);
    _addCoinRow(4400, 470, 5);
    _addCoinRow(5200, 370, 4);
    _addCoinRow(5700, 470, 5);

    add(PowerUpItem(pos: Vector2(1150, 160), type: PowerUpType.bigWeapon));
    add(PowerUpItem(pos: Vector2(2350, 170), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(4350, 160), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(5350, 230), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:6150));
  }

  void _buildLevel6() {
    // Gaps ~120 (wider from here)
    _addPlatform(0, 500, 900, 100);
    _addPlatform(1020, 500, 800, 100);
    _addPlatform(1940, 500, 900, 100);
    _addPlatform(2960, 500, 800, 100);
    _addPlatform(3880, 500, 900, 100);
    _addPlatform(4900, 500, 800, 100);
    _addPlatform(5820, 500, 900, 100);

    // Tier 1
    _addPlatform(300, 400, 120, 20);
    _addPlatform(700, 360, 140, 20);
    _addPlatform(1150, 400, 120, 20);
    _addPlatform(1600, 380, 140, 20);
    _addPlatform(2100, 360, 120, 20);
    _addPlatform(2600, 400, 120, 20);
    _addPlatform(3100, 370, 140, 20);
    _addPlatform(3600, 390, 120, 20);
    _addPlatform(4100, 360, 140, 20);
    _addPlatform(4600, 380, 120, 20);
    _addPlatform(5100, 400, 120, 20);
    _addPlatform(5600, 370, 140, 20);
    _addPlatform(6100, 380, 120, 20);
    _addPlatform(6400, 390, 120, 20);
    // Tier 2
    _addPlatform(500, 270, 140, 20);
    _addPlatform(1400, 280, 120, 20);
    _addPlatform(2400, 260, 140, 20);
    _addPlatform(3400, 270, 120, 20);
    _addPlatform(4400, 280, 120, 20);
    _addPlatform(5400, 260, 140, 20);
    _addPlatform(6200, 270, 120, 20);
    // Tier 3
    _addPlatform(900, 190, 120, 20);
    _addPlatform(1900, 200, 100, 20);
    _addPlatform(3000, 190, 120, 20);
    _addPlatform(4900, 200, 100, 20);
    _addPlatform(6000, 190, 100, 20);

    add(Enemy(pos: Vector2(500, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(1300, 464), patrolSpeed: 60, patrolRange: 80));
    add(Enemy(pos: Vector2(2200, 464), patrolSpeed: 55, patrolRange: 90));
    add(Enemy(pos: Vector2(3200, 464), patrolSpeed: 65, patrolRange: 80));
    add(Enemy(pos: Vector2(4200, 464), patrolSpeed: 60, patrolRange: 70));
    add(Enemy(pos: Vector2(5200, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(6200, 464), patrolSpeed: 70, patrolRange: 70, hp: 2));
    add(Enemy(pos: Vector2(6500, 464), patrolSpeed: 60, patrolRange: 70));
    add(Enemy(pos: Vector2(3700, 464), patrolSpeed: 60, patrolRange: 70));
    add(Enemy(pos: Vector2(1450, 254), patrolSpeed: 30, patrolRange: 50));
    add(Enemy(pos: Vector2(4450, 254), patrolSpeed: 35, patrolRange: 50));

    _addCoinRow(100, 470, 6);
    _addCoinRow(550, 330, 4);
    _addCoinRow(1200, 470, 6);
    _addCoinRow(1650, 350, 4);
    _addCoinRow(2500, 470, 5);
    _addCoinRow(3200, 340, 4);
    _addCoinRow(4000, 470, 6);
    _addCoinRow(4700, 350, 4);
    _addCoinRow(5500, 470, 5);
    _addCoinRow(6200, 470, 5);

    add(PowerUpItem(pos: Vector2(950, 160), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(1950, 170), type: PowerUpType.extraAmmo));
    add(PowerUpItem(pos: Vector2(3050, 160), type: PowerUpType.bigWeapon));
    add(PowerUpItem(pos: Vector2(4950, 170), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:6600));
  }

  void _buildLevel7() {
    // Gaps ~130
    _addPlatform(0, 500, 1000, 100);
    _addPlatform(1130, 500, 850, 100);
    _addPlatform(2110, 500, 800, 100);
    _addPlatform(3040, 500, 900, 100);
    _addPlatform(4070, 500, 800, 100);
    _addPlatform(5000, 500, 900, 100);
    _addPlatform(6030, 500, 1000, 100);

    // Tier 1
    _addPlatform(300, 400, 120, 20);
    _addPlatform(700, 370, 140, 20);
    _addPlatform(1250, 390, 120, 20);
    _addPlatform(1700, 360, 140, 20);
    _addPlatform(2300, 400, 120, 20);
    _addPlatform(2800, 370, 120, 20);
    _addPlatform(3300, 390, 140, 20);
    _addPlatform(3800, 360, 120, 20);
    _addPlatform(4300, 380, 140, 20);
    _addPlatform(4800, 370, 120, 20);
    _addPlatform(5300, 400, 120, 20);
    _addPlatform(5800, 370, 140, 20);
    _addPlatform(6300, 390, 120, 20);
    _addPlatform(6700, 380, 120, 20);
    // Tier 2
    _addPlatform(500, 280, 120, 20);
    _addPlatform(1500, 270, 140, 20);
    _addPlatform(2600, 260, 120, 20);
    _addPlatform(3600, 280, 120, 20);
    _addPlatform(4600, 270, 140, 20);
    _addPlatform(5600, 260, 120, 20);
    // Tier 3
    _addPlatform(900, 190, 120, 20);
    _addPlatform(2000, 200, 120, 20);
    _addPlatform(3200, 190, 100, 20);
    _addPlatform(5100, 200, 120, 20);
    _addPlatform(6500, 190, 100, 20);

    add(Enemy(pos: Vector2(400, 464), patrolSpeed: 55, patrolRange: 80));
    add(Enemy(pos: Vector2(1300, 464), patrolSpeed: 60, patrolRange: 80));
    add(Enemy(pos: Vector2(2400, 464), patrolSpeed: 65, patrolRange: 80));
    add(Enemy(pos: Vector2(3300, 464), patrolSpeed: 60, patrolRange: 90));
    add(Enemy(pos: Vector2(4300, 464), patrolSpeed: 65, patrolRange: 70));
    add(Enemy(pos: Vector2(5300, 464), patrolSpeed: 70, patrolRange: 80));
    add(Enemy(pos: Vector2(6300, 464), patrolSpeed: 60, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(6800, 464), patrolSpeed: 65, patrolRange: 70, hp: 2));
    add(Enemy(pos: Vector2(1550, 244), patrolSpeed: 35, patrolRange: 50));
    add(Enemy(pos: Vector2(4650, 244), patrolSpeed: 30, patrolRange: 50));

    _addCoinRow(100, 470, 6);
    _addCoinRow(550, 340, 4);
    _addCoinRow(1300, 470, 5);
    _addCoinRow(1750, 330, 4);
    _addCoinRow(2500, 470, 6);
    _addCoinRow(3400, 360, 4);
    _addCoinRow(4200, 470, 5);
    _addCoinRow(5000, 340, 4);
    _addCoinRow(5800, 470, 6);
    _addCoinRow(6500, 470, 5);

    add(PowerUpItem(pos: Vector2(950, 160), type: PowerUpType.speedBoost));
    add(PowerUpItem(pos: Vector2(2050, 170), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(3250, 160), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(5150, 170), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:6900));
  }

  void _buildLevel8() {
    // Gaps ~140
    _addPlatform(0, 500, 900, 100);
    _addPlatform(1040, 500, 850, 100);
    _addPlatform(2030, 500, 800, 100);
    _addPlatform(2970, 500, 850, 100);
    _addPlatform(3960, 500, 800, 100);
    _addPlatform(4900, 500, 900, 100);
    _addPlatform(5940, 500, 850, 100);
    _addPlatform(6930, 500, 900, 100);

    // Tier 1
    _addPlatform(300, 400, 120, 20);
    _addPlatform(650, 360, 120, 20);
    _addPlatform(1200, 390, 120, 20);
    _addPlatform(1600, 360, 140, 20);
    _addPlatform(2200, 400, 120, 20);
    _addPlatform(2700, 370, 120, 20);
    _addPlatform(3200, 390, 140, 20);
    _addPlatform(3700, 360, 120, 20);
    _addPlatform(4200, 380, 120, 20);
    _addPlatform(4700, 360, 140, 20);
    _addPlatform(5200, 400, 120, 20);
    _addPlatform(5700, 370, 120, 20);
    _addPlatform(6200, 390, 140, 20);
    _addPlatform(6700, 360, 120, 20);
    _addPlatform(7200, 380, 120, 20);
    _addPlatform(7500, 370, 120, 20);
    // Tier 2
    _addPlatform(500, 280, 120, 20);
    _addPlatform(1400, 270, 140, 20);
    _addPlatform(2500, 260, 120, 20);
    _addPlatform(3500, 280, 120, 20);
    _addPlatform(4500, 260, 140, 20);
    _addPlatform(5500, 270, 120, 20);
    _addPlatform(6500, 260, 120, 20);
    _addPlatform(7300, 270, 120, 20);
    // Tier 3
    _addPlatform(900, 190, 120, 20);
    _addPlatform(2100, 200, 100, 20);
    _addPlatform(3900, 190, 120, 20);
    _addPlatform(5000, 200, 100, 20);
    _addPlatform(6900, 190, 120, 20);

    add(Enemy(pos: Vector2(500, 464), patrolSpeed: 60, patrolRange: 80));
    add(Enemy(pos: Vector2(1300, 464), patrolSpeed: 65, patrolRange: 80));
    add(Enemy(pos: Vector2(2400, 464), patrolSpeed: 60, patrolRange: 90));
    add(Enemy(pos: Vector2(3400, 464), patrolSpeed: 65, patrolRange: 80));
    add(Enemy(pos: Vector2(4400, 464), patrolSpeed: 70, patrolRange: 70));
    add(Enemy(pos: Vector2(5400, 464), patrolSpeed: 65, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(6300, 464), patrolSpeed: 70, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(7100, 464), patrolSpeed: 75, patrolRange: 70, hp: 2));
    add(Enemy(pos: Vector2(7500, 464), patrolSpeed: 70, patrolRange: 70, hp: 2));
    add(Enemy(pos: Vector2(1450, 244), patrolSpeed: 35, patrolRange: 50));
    add(Enemy(pos: Vector2(4550, 234), patrolSpeed: 30, patrolRange: 50));
    add(Enemy(pos: Vector2(6550, 234), patrolSpeed: 35, patrolRange: 40));

    _addCoinRow(100, 470, 6);
    _addCoinRow(500, 330, 4);
    _addCoinRow(1200, 470, 5);
    _addCoinRow(1650, 330, 4);
    _addCoinRow(2500, 470, 6);
    _addCoinRow(3300, 360, 4);
    _addCoinRow(4100, 470, 5);
    _addCoinRow(4750, 330, 4);
    _addCoinRow(5500, 470, 6);
    _addCoinRow(6300, 360, 4);
    _addCoinRow(7000, 470, 5);

    add(PowerUpItem(pos: Vector2(950, 160), type: PowerUpType.bigWeapon));
    add(PowerUpItem(pos: Vector2(2150, 170), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(3950, 160), type: PowerUpType.extraAmmo));
    add(PowerUpItem(pos: Vector2(5050, 170), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(6950, 160), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:7700));
  }

  void _buildLevel9() {
    // Gaps ~150
    _addPlatform(0, 500, 950, 100);
    _addPlatform(1100, 500, 800, 100);
    _addPlatform(2050, 500, 850, 100);
    _addPlatform(3050, 500, 800, 100);
    _addPlatform(4000, 500, 850, 100);
    _addPlatform(5000, 500, 800, 100);
    _addPlatform(5950, 500, 900, 100);
    _addPlatform(7000, 500, 900, 100);

    // Tier 1
    _addPlatform(300, 400, 120, 20);
    _addPlatform(700, 360, 120, 20);
    _addPlatform(1250, 390, 140, 20);
    _addPlatform(1650, 360, 120, 20);
    _addPlatform(2200, 380, 120, 20);
    _addPlatform(2700, 360, 140, 20);
    _addPlatform(3300, 390, 120, 20);
    _addPlatform(3700, 360, 120, 20);
    _addPlatform(4200, 380, 140, 20);
    _addPlatform(4700, 360, 120, 20);
    _addPlatform(5200, 390, 120, 20);
    _addPlatform(5700, 360, 140, 20);
    _addPlatform(6200, 380, 120, 20);
    _addPlatform(6700, 360, 120, 20);
    _addPlatform(7200, 390, 140, 20);
    _addPlatform(7600, 370, 120, 20);
    // Tier 2
    _addPlatform(500, 270, 120, 20);
    _addPlatform(1450, 280, 140, 20);
    _addPlatform(2500, 260, 120, 20);
    _addPlatform(3500, 270, 140, 20);
    _addPlatform(4500, 260, 120, 20);
    _addPlatform(5500, 270, 120, 20);
    _addPlatform(6500, 260, 140, 20);
    _addPlatform(7400, 270, 120, 20);
    // Tier 3
    _addPlatform(900, 190, 100, 20);
    _addPlatform(2100, 200, 120, 20);
    _addPlatform(3200, 190, 100, 20);
    _addPlatform(4900, 200, 120, 20);
    _addPlatform(6100, 190, 100, 20);
    _addPlatform(7300, 200, 100, 20);

    add(Enemy(pos: Vector2(400, 464), patrolSpeed: 60, patrolRange: 80));
    add(Enemy(pos: Vector2(1300, 464), patrolSpeed: 65, patrolRange: 80));
    add(Enemy(pos: Vector2(2300, 464), patrolSpeed: 65, patrolRange: 90));
    add(Enemy(pos: Vector2(3300, 464), patrolSpeed: 70, patrolRange: 80));
    add(Enemy(pos: Vector2(4300, 464), patrolSpeed: 70, patrolRange: 70, hp: 2));
    add(Enemy(pos: Vector2(5300, 464), patrolSpeed: 75, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(6300, 464), patrolSpeed: 70, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(7200, 464), patrolSpeed: 75, patrolRange: 70, hp: 2));
    add(Enemy(pos: Vector2(7600, 464), patrolSpeed: 80, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(1500, 254), patrolSpeed: 35, patrolRange: 50));
    add(Enemy(pos: Vector2(4550, 234), patrolSpeed: 30, patrolRange: 50));
    add(Enemy(pos: Vector2(6550, 234), patrolSpeed: 35, patrolRange: 40));

    _addCoinRow(100, 470, 6);
    _addCoinRow(550, 330, 4);
    _addCoinRow(1300, 470, 5);
    _addCoinRow(1700, 330, 4);
    _addCoinRow(2500, 470, 6);
    _addCoinRow(3400, 360, 4);
    _addCoinRow(4200, 470, 5);
    _addCoinRow(4750, 330, 4);
    _addCoinRow(5400, 470, 6);
    _addCoinRow(6300, 350, 4);
    _addCoinRow(7100, 470, 6);
    _addCoinRow(7500, 340, 3);

    add(PowerUpItem(pos: Vector2(950, 160), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(2150, 170), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(3250, 160), type: PowerUpType.bigWeapon));
    add(PowerUpItem(pos: Vector2(4950, 170), type: PowerUpType.extraAmmo));
    add(PowerUpItem(pos: Vector2(6150, 160), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:7800));
  }

  void _buildLevel10() {
    // Gaps ~160 — hardest level
    _addPlatform(0, 500, 900, 100);
    _addPlatform(1060, 500, 800, 100);
    _addPlatform(2020, 500, 850, 100);
    _addPlatform(3030, 500, 800, 100);
    _addPlatform(3990, 500, 850, 100);
    _addPlatform(5000, 500, 800, 100);
    _addPlatform(5960, 500, 850, 100);
    _addPlatform(6970, 500, 900, 100);
    _addPlatform(8030, 500, 900, 100);

    // Tier 1
    _addPlatform(300, 400, 120, 20);
    _addPlatform(650, 350, 120, 20);
    _addPlatform(1200, 390, 120, 20);
    _addPlatform(1600, 350, 140, 20);
    _addPlatform(2200, 380, 120, 20);
    _addPlatform(2700, 350, 120, 20);
    _addPlatform(3200, 390, 140, 20);
    _addPlatform(3700, 350, 120, 20);
    _addPlatform(4200, 370, 120, 20);
    _addPlatform(4700, 350, 140, 20);
    _addPlatform(5200, 390, 120, 20);
    _addPlatform(5700, 350, 120, 20);
    _addPlatform(6200, 370, 140, 20);
    _addPlatform(6700, 350, 120, 20);
    _addPlatform(7200, 390, 120, 20);
    _addPlatform(7600, 370, 140, 20);
    _addPlatform(8200, 380, 120, 20);
    _addPlatform(8600, 360, 120, 20);
    // Tier 2
    _addPlatform(500, 270, 120, 20);
    _addPlatform(1400, 260, 140, 20);
    _addPlatform(2500, 250, 120, 20);
    _addPlatform(3500, 260, 140, 20);
    _addPlatform(4500, 250, 120, 20);
    _addPlatform(5500, 260, 120, 20);
    _addPlatform(6500, 250, 140, 20);
    _addPlatform(7400, 260, 120, 20);
    _addPlatform(8400, 250, 120, 20);
    // Tier 3
    _addPlatform(850, 180, 120, 20);
    _addPlatform(2100, 190, 100, 20);
    _addPlatform(3300, 180, 120, 20);
    _addPlatform(4900, 190, 100, 20);
    _addPlatform(6100, 180, 120, 20);
    _addPlatform(7800, 190, 100, 20);

    add(Enemy(pos: Vector2(400, 464), patrolSpeed: 65, patrolRange: 80));
    add(Enemy(pos: Vector2(1300, 464), patrolSpeed: 70, patrolRange: 70));
    add(Enemy(pos: Vector2(2300, 464), patrolSpeed: 65, patrolRange: 90, hp: 2));
    add(Enemy(pos: Vector2(3300, 464), patrolSpeed: 75, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(4300, 464), patrolSpeed: 70, patrolRange: 70, hp: 2));
    add(Enemy(pos: Vector2(5300, 464), patrolSpeed: 75, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(6300, 464), patrolSpeed: 70, patrolRange: 80, hp: 2));
    add(Enemy(pos: Vector2(7300, 464), patrolSpeed: 80, patrolRange: 80, hp: 3));
    add(Enemy(pos: Vector2(8300, 464), patrolSpeed: 75, patrolRange: 70, hp: 3));
    add(Enemy(pos: Vector2(8700, 464), patrolSpeed: 80, patrolRange: 80, hp: 3));
    add(Enemy(pos: Vector2(1450, 234), patrolSpeed: 35, patrolRange: 50));
    add(Enemy(pos: Vector2(3550, 234), patrolSpeed: 35, patrolRange: 50));
    add(Enemy(pos: Vector2(6550, 224), patrolSpeed: 30, patrolRange: 40));
    add(Enemy(pos: Vector2(8450, 224), patrolSpeed: 35, patrolRange: 40));

    _addCoinRow(100, 470, 6);
    _addCoinRow(550, 320, 4);
    _addCoinRow(1200, 470, 6);
    _addCoinRow(1650, 320, 4);
    _addCoinRow(2500, 470, 6);
    _addCoinRow(3300, 360, 4);
    _addCoinRow(4200, 470, 5);
    _addCoinRow(4750, 320, 4);
    _addCoinRow(5400, 470, 6);
    _addCoinRow(6300, 340, 4);
    _addCoinRow(7100, 470, 6);
    _addCoinRow(7700, 360, 4);
    _addCoinRow(8200, 470, 5);

    add(PowerUpItem(pos: Vector2(900, 150), type: PowerUpType.shield));
    add(PowerUpItem(pos: Vector2(2150, 160), type: PowerUpType.bigWeapon));
    add(PowerUpItem(pos: Vector2(3350, 150), type: PowerUpType.heal));
    add(PowerUpItem(pos: Vector2(4950, 160), type: PowerUpType.extraAmmo));
    add(PowerUpItem(pos: Vector2(6150, 150), type: PowerUpType.speedBoost));
    add(PowerUpItem(pos: Vector2(7850, 160), type: PowerUpType.angelProtection));

    add(BossArena(theme: _theme, arenaX:8800));
  }

  void _addPlatform(double x, double y, double w, double h) {
    add(PlatformBlock(pos: Vector2(x, y), blockSize: Vector2(w, h), theme: _theme));
  }

  void _addCoinRow(double startX, double y, int count) {
    for (int i = 0; i < count; i++) {
      add(Coin(pos: Vector2(startX + i * 30, y)));
    }
  }

  void _addPitWalls() {
    final grounds = <List<double>>[];
    for (final child in children) {
      if (child is PlatformBlock && child.size.y >= 50) {
        grounds.add([child.position.x, child.position.x + child.size.x, child.position.y]);
      }
    }
    grounds.sort((a, b) => a[0].compareTo(b[0]));
    for (int i = 0; i < grounds.length - 1; i++) {
      final rightEdge = grounds[i][1];
      final leftEdge = grounds[i + 1][0];
      final gap = leftEdge - rightEdge;
      if (gap > 20) {
        final wallY = grounds[i][2];
        // Left wall (right edge of left platform)
        add(PlatformBlock(
          pos: Vector2(rightEdge, wallY),
          blockSize: Vector2(6, 300),
          invisible: true,
        ));
        // Right wall (left edge of right platform)
        add(PlatformBlock(
          pos: Vector2(leftEdge - 6, wallY),
          blockSize: Vector2(6, 300),
          invisible: true,
        ));
      }
    }
  }
}
