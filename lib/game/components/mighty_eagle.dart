import 'dart:math' show Random, max, sin;
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pata_game.dart';
import 'mystery_box.dart';
import 'platform_block.dart';

class MightyEagle extends PositionComponent with HasGameRef<PataGame> {
  final double triggerX;
  bool _spawned = false;
  bool _dropped = false;
  double _wingPhase = 0;

  Sprite? _sprite;

  static final _rng = Random();
  // The sprite lives in assets/sprites/, not in Flame's default assets/images/.
  // Shared cache so the image is decoded once, not on every level (re)load.
  static final _images = Images(prefix: 'assets/sprites/');

  static const _width = 90.0;
  // Flight height below the top of the screen, clear of the HUD rows.
  static const _skyOffset = 55.0;
  // How far ahead of the player the box is dropped.
  static const _dropLead = 150.0;

  MightyEagle({required this.triggerX}) {
    size = Vector2(_width, _width / 2);
  }

  @override
  Future<void> onLoad() async {
    // onLoad must never throw: a component that fails to load blocks Flame's
    // lifecycle queue for its parent (the whole level), so the boss, arena
    // walls and loot never get mounted and the level is never removed on
    // restart. Without the sprite we fall back to the drawn eagle in render().
    try {
      final image = await _images.load('mighty_eagle.png');
      _sprite = Sprite(image);
      size = Vector2(_width, _width * image.height / image.width);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    final player = gameRef.player;
    final camera = gameRef.camera.viewfinder.position;

    if (!_spawned) {
      if (player.position.x >= triggerX) {
        _spawned = true;
        position = Vector2(camera.x - size.x, camera.y + _skyOffset);
      }
      return;
    }

    _wingPhase += dt * 8;
    // Always faster than the player, so it overtakes them and the box lands
    // ahead. (Flying at a fixed 220 px/s to a fixed point, the box landed
    // behind a running player.)
    position.x += (220 + max(0.0, player.velocity.x)) * dt;
    // Stay near the top of the screen; the camera follows the player's height
    // (at a fixed y = 120 the eagle flew above the visible area).
    position.y = camera.y + _skyOffset + sin(_wingPhase) * 15;

    final centerX = position.x + size.x / 2;
    if (!_dropped &&
        centerX >= player.position.x + player.size.x + _dropLead &&
        _isOverGround(centerX)) {
      _dropped = true;
      final direction = _rng.nextBool() ? 1 : -1;
      parent?.add(MysteryBox(
        pos: Vector2(centerX - 16, position.y + size.y),
        scaleDirection: direction,
      ));
    }

    if (_dropped && position.x > camera.x + gameRef.size.x + 100) {
      removeFromParent();
    }
  }

  // MysteryBox always settles at ground height, so drop it only above solid
  // ground, never above a pit.
  bool _isOverGround(double x) =>
      parent!.children.whereType<PlatformBlock>().any((p) =>
          !p.invisible &&
          p.size.y >= 50 &&
          p.position.x <= x - 16 &&
          p.position.x + p.size.x >= x + 16);

  @override
  void render(Canvas canvas) {
    if (!_spawned) return;

    if (_sprite != null) {
      final wobble = sin(_wingPhase) * 0.15;
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(wobble);
      _sprite!.render(
        canvas,
        position: Vector2(-size.x / 2, -size.y / 2),
        size: size,
      );
      canvas.restore();
    } else {
      final paint = Paint()..color = const Color(0xFF5C3A1E);
      canvas.drawOval(Rect.fromLTWH(10, 15, 40, 30), paint);
      canvas.drawOval(
        Rect.fromLTWH(0, 20, 20, 15),
        Paint()..color = const Color(0xFF8B6914),
      );
      canvas.drawOval(
        Rect.fromLTWH(40, 20, 20, 15),
        Paint()..color = const Color(0xFF8B6914),
      );
    }
  }
}
