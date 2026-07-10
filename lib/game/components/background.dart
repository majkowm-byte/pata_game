import 'dart:math' show sin, cos, pi;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum LevelTheme { meadow, forest, jungle, desert, space, lava }

class Background extends PositionComponent with HasGameRef {
  final LevelTheme theme;
  final double worldWidth;
  double _phase = 0;
  double _phase2 = 0;

  Background({this.theme = LevelTheme.meadow, this.worldWidth = 10000});

  @override
  Future<void> onLoad() async {
    size = Vector2(worldWidth, 600);
    priority = -10;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * 8;
    _phase2 += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    switch (theme) {
      case LevelTheme.meadow:
        _renderMeadow(canvas);
      case LevelTheme.forest:
        _renderForest(canvas);
      case LevelTheme.jungle:
        _renderJungle(canvas);
      case LevelTheme.desert:
        _renderDesert(canvas);
      case LevelTheme.space:
        _renderSpace(canvas);
      case LevelTheme.lava:
        _renderLava(canvas);
    }
  }

  void _renderSky(Canvas canvas, List<Color> colors, {List<double>? stops}) {
    final skyRect = Rect.fromLTWH(0, 0, size.x, size.y * 0.7);
    canvas.drawRect(
      skyRect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: colors, stops: stops,
      ).createShader(skyRect),
    );
  }

  void _renderGround(Canvas canvas, List<Color> colors) {
    final groundRect = Rect.fromLTWH(0, size.y * 0.68, size.x, size.y * 0.32);
    canvas.drawRect(
      groundRect,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(groundRect),
    );
  }

  void _renderClouds(Canvas canvas, {Color color = Colors.white, double opacity = 0.6}) {
    final p1 = Paint()..color = color.withOpacity(opacity);
    final p2 = Paint()..color = color.withOpacity(opacity + 0.15);
    for (int i = 0; i < 12; i++) {
      final baseX = 100 + i * 420.0;
      final drift = sin(_phase * 0.02 + i * 0.8) * 15;
      final y = 40 + (i % 3) * 30.0 + sin(i * 1.5) * 20;
      final w = 80 + (i % 4) * 25.0;
      canvas.drawOval(Rect.fromCenter(center: Offset(baseX + drift, y), width: w, height: 25), p1);
      canvas.drawOval(Rect.fromCenter(center: Offset(baseX + drift + w * 0.25, y - 8), width: w * 0.6, height: 18), p2);
    }
  }

  void _renderGrass(Canvas canvas, Color color) {
    final grassPaint = Paint()..color = color..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.x; x += 18) {
      final baseY = size.y * 0.68;
      final sway = sin(_phase2 + x * 0.15) * 2;
      final h = 5 + (x.toInt() % 7) * 1.5;
      canvas.drawLine(Offset(x, baseY), Offset(x + sway, baseY - h), grassPaint);
    }
  }

  void _renderMeadow(Canvas canvas) {
    _renderSky(canvas, [const Color(0xFF5BA3D9), const Color(0xFF87CEEB), const Color(0xFFB0E0E6)]);

    // Sun
    canvas.drawCircle(const Offset(200, 80), 40, Paint()..color = const Color(0xFFFFF9C4).withOpacity(0.3));
    canvas.drawCircle(const Offset(200, 80), 25, Paint()..color = const Color(0xFFFFEB3B).withOpacity(0.5));
    canvas.drawCircle(const Offset(200, 80), 15, Paint()..color = const Color(0xFFFFD54F));

    _renderClouds(canvas);

    // Hills
    for (double x = 0; x < size.x; x += 250) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x + 125, size.y * 0.7), width: 300, height: 100), Paint()..color = const Color(0xFF90C695));
    }

    _renderGround(canvas, [const Color(0xFF5a9e30), const Color(0xFF3d7a1a), const Color(0xFF2d5a10)]);
    _renderGrass(canvas, const Color(0xFF6abf3b));

    // Flowers
    final flowerColors = [Colors.red, Colors.yellow, Colors.pink, Colors.white];
    for (double x = 50; x < size.x; x += 120) {
      final color = flowerColors[(x.toInt() ~/ 120) % flowerColors.length];
      final baseY = size.y * 0.68 - 2;
      final sway = sin(_phase2 * 0.8 + x * 0.1) * 1.5;
      canvas.drawLine(Offset(x, baseY + 4), Offset(x + sway, baseY - 6), Paint()..color = const Color(0xFF4a8a20)..strokeWidth = 1);
      canvas.drawCircle(Offset(x + sway, baseY - 7), 3, Paint()..color = color);
      canvas.drawCircle(Offset(x + sway, baseY - 7), 1.5, Paint()..color = Colors.yellow);
    }
  }

  void _renderForest(Canvas canvas) {
    _renderSky(canvas, [const Color(0xFF3A6B35), const Color(0xFF5B8A4A), const Color(0xFF8BB174)]);
    _renderClouds(canvas, opacity: 0.3);

    // Trees in background
    final treePaint = Paint()..color = const Color(0xFF2D5A27);
    final trunkPaint = Paint()..color = const Color(0xFF4A3520);
    for (double x = 0; x < size.x; x += 80) {
      final h = 60 + sin(x * 0.03) * 25;
      final baseY = size.y * 0.68;
      canvas.drawRect(Rect.fromLTWH(x + 35, baseY - h + 20, 10, h - 20), trunkPaint);
      final treePath = Path()
        ..moveTo(x + 10, baseY - h + 30)
        ..lineTo(x + 40, baseY - h - 20)
        ..lineTo(x + 70, baseY - h + 30)
        ..close();
      canvas.drawPath(treePath, treePaint);
      canvas.drawPath(
        Path()..moveTo(x + 15, baseY - h + 10)..lineTo(x + 40, baseY - h - 40)..lineTo(x + 65, baseY - h + 10)..close(),
        Paint()..color = const Color(0xFF1E4D1A),
      );
    }

    _renderGround(canvas, [const Color(0xFF3B6D2E), const Color(0xFF2A5220), const Color(0xFF1A3A14)]);
    _renderGrass(canvas, const Color(0xFF4A8A3A));
  }

  void _renderJungle(Canvas canvas) {
    _renderSky(canvas, [const Color(0xFF1B4332), const Color(0xFF2D6A4F), const Color(0xFF52B788)]);

    // Dense vines
    final vinePaint = Paint()..color = const Color(0xFF40916C)..strokeWidth = 2;
    for (double x = 0; x < size.x; x += 60) {
      for (double y = 0; y < size.y * 0.5; y += 15) {
        final sway = sin(_phase2 * 0.5 + x * 0.1 + y * 0.05) * 8;
        canvas.drawLine(Offset(x + sway, y), Offset(x + sway, y + 15), vinePaint);
      }
    }

    // Large leaves
    for (double x = 30; x < size.x; x += 150) {
      final baseY = size.y * 0.68;
      final leafPath = Path()
        ..moveTo(x, baseY - 40)
        ..quadraticBezierTo(x + 30, baseY - 70, x + 60, baseY - 35)
        ..quadraticBezierTo(x + 30, baseY - 50, x, baseY - 40);
      canvas.drawPath(leafPath, Paint()..color = const Color(0xFF2D6A4F).withOpacity(0.6));
    }

    _renderGround(canvas, [const Color(0xFF2D6A4F), const Color(0xFF1B4332), const Color(0xFF081C15)]);
    _renderGrass(canvas, const Color(0xFF52B788));
  }

  void _renderDesert(Canvas canvas) {
    _renderSky(canvas, [const Color(0xFFFF8C00), const Color(0xFFFFB347), const Color(0xFFFFE4B5)]);

    // Big sun
    canvas.drawCircle(const Offset(300, 90), 60, Paint()..color = const Color(0xFFFFD700).withOpacity(0.3));
    canvas.drawCircle(const Offset(300, 90), 35, Paint()..color = const Color(0xFFFFD700).withOpacity(0.6));
    canvas.drawCircle(const Offset(300, 90), 20, Paint()..color = const Color(0xFFFFD700));

    // Sand dunes
    for (double x = 0; x < size.x; x += 300) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 150, size.y * 0.7), width: 400, height: 80),
        Paint()..color = const Color(0xFFDEB887).withOpacity(0.5),
      );
    }

    // Cacti
    final cactusPaint = Paint()..color = const Color(0xFF228B22);
    for (double x = 100; x < size.x; x += 400) {
      final baseY = size.y * 0.68;
      canvas.drawRect(Rect.fromLTWH(x, baseY - 35, 8, 35), cactusPaint);
      canvas.drawRect(Rect.fromLTWH(x - 10, baseY - 25, 10, 6), cactusPaint);
      canvas.drawRect(Rect.fromLTWH(x - 10, baseY - 25, 6, -12), cactusPaint);
      canvas.drawRect(Rect.fromLTWH(x + 8, baseY - 18, 10, 6), cactusPaint);
      canvas.drawRect(Rect.fromLTWH(x + 12, baseY - 18, 6, -10), cactusPaint);
    }

    _renderGround(canvas, [const Color(0xFFDEB887), const Color(0xFFC4A882), const Color(0xFFA0886A)]);
  }

  void _renderSpace(Canvas canvas) {
    // Dark space sky
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), Paint()..color = const Color(0xFF0A0A2E));

    // Stars
    for (int i = 0; i < 200; i++) {
      final x = (i * 37.7 + sin(i * 0.3) * 50) % size.x;
      final y = (i * 13.3 + cos(i * 0.5) * 30) % (size.y * 0.68);
      final twinkle = (sin(_phase * 0.1 + i) * 0.5 + 0.5).clamp(0.2, 1.0);
      final s = (i % 3 == 0) ? 2.0 : 1.0;
      canvas.drawCircle(Offset(x, y), s, Paint()..color = Colors.white.withOpacity(twinkle));
    }

    // Planets
    canvas.drawCircle(const Offset(800, 100), 30, Paint()..color = const Color(0xFF8B4513).withOpacity(0.7));
    canvas.drawCircle(const Offset(800, 100), 30, Paint()..color = const Color(0xFFA0522D).withOpacity(0.3));
    // Ring
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(800, 100), width: 80, height: 15),
      Paint()..color = const Color(0xFFDEB887).withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 3,
    );

    // Nebula
    canvas.drawCircle(const Offset(2000, 120), 80, Paint()..color = const Color(0xFF9B30FF).withOpacity(0.08));
    canvas.drawCircle(const Offset(2050, 100), 50, Paint()..color = const Color(0xFF4169E1).withOpacity(0.1));

    _renderGround(canvas, [const Color(0xFF2F2F4F), const Color(0xFF1A1A3E), const Color(0xFF0A0A2E)]);
  }

  void _renderLava(Canvas canvas) {
    _renderSky(canvas, [const Color(0xFF1A0000), const Color(0xFF4A0000), const Color(0xFF8B0000)]);

    // Volcanic mountains
    for (double x = 0; x < size.x; x += 400) {
      final path = Path()
        ..moveTo(x, size.y * 0.68)
        ..lineTo(x + 200, size.y * 0.2)
        ..lineTo(x + 400, size.y * 0.68)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF2D0000));

      // Crater glow
      canvas.drawCircle(Offset(x + 200, size.y * 0.2), 15, Paint()..color = const Color(0xFFFF4500).withOpacity(0.5));
      canvas.drawCircle(Offset(x + 200, size.y * 0.2), 8, Paint()..color = const Color(0xFFFFD700).withOpacity(0.4));
    }

    // Lava flow on ground
    final baseY = size.y * 0.68;
    for (double x = 0; x < size.x; x += 30) {
      final glow = sin(_phase * 0.05 + x * 0.02) * 0.3 + 0.5;
      canvas.drawCircle(
        Offset(x, baseY + 10 + sin(_phase2 + x * 0.1) * 3),
        8,
        Paint()..color = Color.lerp(const Color(0xFFFF4500), const Color(0xFFFFD700), glow)!.withOpacity(0.3),
      );
    }

    _renderGround(canvas, [const Color(0xFF3D0000), const Color(0xFF2A0000), const Color(0xFF1A0000)]);

    // Embers floating up
    for (int i = 0; i < 30; i++) {
      final x = (i * 167.3) % size.x;
      final yBase = size.y * 0.5 + sin(i * 1.7) * 80;
      final y = yBase - (_phase * 2 + i * 30) % (size.y * 0.5);
      final opacity = (1.0 - y / (size.y * 0.5)).clamp(0.0, 0.6);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = const Color(0xFFFF6347).withOpacity(opacity));
    }
  }
}
