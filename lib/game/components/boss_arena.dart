import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../models/boss_data.dart';
import '../pata_game.dart';
import 'background.dart';
import 'platform_block.dart';
import 'boss.dart';
import 'boss_portal.dart';
import 'fire_wall.dart';

class BossArena extends PositionComponent with HasGameRef<PataGame> {
  final double arenaX;
  final double arenaWidth;
  final double groundY;
  final LevelTheme? theme;

  bool _triggered = false;
  bool get triggered => _triggered;

  PlatformBlock? _leftWall;
  PlatformBlock? _rightWall;
  FireWall? _rightFireWall;
  Boss? boss;

  static const _wallHeight = 300.0;

  BossArena({
    required this.arenaX,
    this.arenaWidth = 500,
    this.groundY = 500,
    this.theme,
  });

  @override
  Future<void> onLoad() async {
    // Arena ground platform
    parent?.add(PlatformBlock(
      pos: Vector2(arenaX, groundY),
      blockSize: Vector2(arenaWidth, 100),
      theme: theme,
    ));

    // Right wall (always present) — invisible collision + fire visual
    _rightWall = PlatformBlock(
      pos: Vector2(arenaX + arenaWidth - 6, groundY - _wallHeight),
      blockSize: Vector2(6, _wallHeight + 100),
      invisible: true,
    );
    parent?.add(_rightWall!);
    _rightFireWall = FireWall(
      pos: Vector2(arenaX + arenaWidth - 12, groundY - _wallHeight),
      wallHeight: _wallHeight,
    );
    parent?.add(_rightFireWall!);

    // Trigger zone — wide enough so the player can't skip it by jumping in
    position = Vector2(arenaX, 0);
    size = Vector2(arenaWidth * 0.4, groundY);
    add(RectangleHitbox(isSolid: true));
  }

  void triggerBoss() {
    if (_triggered) return;
    _triggered = true;

    // Close the entrance with a wall — invisible collision + fire visual
    _leftWall = PlatformBlock(
      pos: Vector2(arenaX, groundY - _wallHeight),
      blockSize: Vector2(6, _wallHeight + 100),
      invisible: true,
    );
    parent?.add(_leftWall!);
    parent?.add(FireWall(
      pos: Vector2(arenaX - 4, groundY - _wallHeight),
      wallHeight: _wallHeight,
    ));

    // Start boss intro sequence
    gameRef.startBossIntro(this);
  }

  void spawnBoss() {
    final bossData = BossData.next();
    boss = Boss(
      data: bossData,
      pos: Vector2(arenaX + arenaWidth * 0.5, groundY - 130 * bossData.spriteScale),
      arena: this,
    );
    parent?.add(boss!);
  }

  void onBossDied() {
    // Remove right wall
    _rightWall?.removeFromParent();
    _rightFireWall?.removeFromParent();

    // Extra ground beyond the wall so player can walk to portal
    parent?.add(PlatformBlock(
      pos: Vector2(arenaX + arenaWidth, groundY),
      blockSize: Vector2(200, 100),
      theme: theme,
    ));

    // Portal appears behind the removed wall
    parent?.add(BossPortal(
      pos: Vector2(arenaX + arenaWidth + 80, groundY - 20),
    ));
  }
}
