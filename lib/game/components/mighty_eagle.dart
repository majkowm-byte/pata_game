import 'dart:math' show Random, sin;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../pata_game.dart';
import 'mystery_box.dart';

class MightyEagle extends PositionComponent with HasGameRef<PataGame> {
  final double triggerX;
  bool _spawned = false;
  bool _dropped = false;
  double _wingPhase = 0;
  double _dropX = 0;

  Sprite? _sprite;

  static final _rng = Random();

  MightyEagle({required this.triggerX}) {
    size = Vector2(60, 60);
  }

  @override
  Future<void> onLoad() async {
    final image = await gameRef.images.load('sprites/mighty_eagle.png');
    _sprite = Sprite(image);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_spawned) {
      final playerX = gameRef.player.position.x;
      if (playerX >= triggerX) {
        _spawned = true;
        final cameraX = gameRef.camera.viewfinder.position.x;
        final screenW = gameRef.size.x;
        position = Vector2(cameraX - 80, 120);
        _dropX = cameraX + screenW * 0.5;
      }
      return;
    }

    _wingPhase += dt * 8;
    position.x += 220 * dt;
    position.y = 120 + sin(_wingPhase) * 15;

    if (!_dropped && position.x >= _dropX) {
      _dropped = true;
      final direction = _rng.nextBool() ? 1 : -1;
      parent?.add(MysteryBox(
        pos: Vector2(_dropX, position.y + size.y),
        scaleDirection: direction,
      ));
    }

    if (position.x > _dropX + 800) {
      removeFromParent();
    }
  }

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
