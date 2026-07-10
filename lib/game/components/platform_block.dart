import 'dart:math' show sin;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'background.dart';

class PlatformBlock extends PositionComponent with HasGameRef {
  final Color color;
  final bool invisible;
  double _grassPhase = 0;

  static const _themeColors = <LevelTheme, List<Color>>{
    LevelTheme.meadow: [Color(0xFF4a7a25), Color(0xFF7CCD3B), Color(0xFF8AE040)],
    LevelTheme.forest: [Color(0xFF3B5E2B), Color(0xFF5A8C3A), Color(0xFF6AAF45)],
    LevelTheme.jungle: [Color(0xFF2D6A4F), Color(0xFF40916C), Color(0xFF52B788)],
    LevelTheme.desert: [Color(0xFFC4A050), Color(0xFFDEB06A), Color(0xFFE8C878)],
    LevelTheme.space: [Color(0xFF2A3A6E), Color(0xFF4060A8), Color(0xFF5878C0)],
    LevelTheme.lava: [Color(0xFF8B2020), Color(0xFFB03030), Color(0xFFD04545)],
  };

  static Color bodyFor(LevelTheme t) => _themeColors[t]![0];
  static Color grassFor(LevelTheme t) => _themeColors[t]![1];
  static Color bladeFor(LevelTheme t) => _themeColors[t]![2];

  PlatformBlock({
    required Vector2 pos,
    required Vector2 blockSize,
    this.color = const Color(0xFF4a7a25),
    this.invisible = false,
    LevelTheme? theme,
  }) {
    position = pos;
    size = blockSize;
    if (theme != null) {
      _bodyColor = bodyFor(theme);
      _grassColor = grassFor(theme);
      _bladeColor = bladeFor(theme);
    }
  }

  Color? _bodyColor;
  Color? _grassColor;
  Color? _bladeColor;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _grassPhase += dt * 2.5;
  }

  @override
  void render(Canvas canvas) {
    if (invisible) return;
    final body = _bodyColor ?? color;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [body, Color.lerp(body, Colors.black, 0.3)!],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    final linePaint = Paint()..color = Colors.black.withOpacity(0.08)..strokeWidth = 0.5;
    for (double y = 8; y < size.y; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), linePaint);
      final offset = (y ~/ 16) % 2 == 0 ? 0.0 : 16.0;
      for (double x = offset; x < size.x; x += 32) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 16), linePaint);
      }
    }

    final gc = _grassColor ?? const Color(0xFF7CCD3B);
    final gcDark = Color.lerp(gc, Colors.black, 0.15)!;
    final grassGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [gc, gcDark],
    );
    final grassRect = Rect.fromLTWH(0, 0, size.x, 6);
    canvas.drawRect(grassRect, Paint()..shader = grassGradient.createShader(grassRect));

    final bc = _bladeColor ?? const Color(0xFF8AE040);
    final bladePaint = Paint()..color = bc..strokeWidth = 1.2..strokeCap = StrokeCap.round;
    for (double x = 2; x < size.x; x += 6) {
      final sway = sin(_grassPhase + x * 0.2) * 1.5;
      final h = 3 + (x.toInt() % 5) * 0.8;
      canvas.drawLine(Offset(x, 0), Offset(x + sway, -h), bladePaint);
    }

    canvas.drawLine(
      Offset.zero,
      Offset(size.x, 0),
      Paint()..color = Colors.white.withOpacity(0.15)..strokeWidth = 1,
    );
  }
}
