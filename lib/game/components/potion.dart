import 'dart:math' show sin, cos, pi;
import 'dart:ui' as ui;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/potion_type.dart';

/// Healing potion dropped where a fat mob died. Pops out of the body, lands at
/// its feet and stays there until picked up.
class Potion extends PositionComponent {
  final PotionType type;
  final double _restY;
  bool collected = false;

  double _age = 0;
  double _vy = -230;
  bool _landed = false;

  // Right after popping out it can't be picked up yet, so the player sees it
  // land instead of grabbing it mid-air.
  static const _pickupDelay = 0.4;

  Potion({required this.type, required Vector2 feet}) : _restY = feet.y - type.height {
    size = Vector2(type.width, type.height);
    position = Vector2(feet.x - type.width / 2, _restY - 24);
  }

  bool get canBePicked => !collected && _age >= _pickupDelay;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (!_landed) {
      _vy += 900 * dt;
      position.y += _vy * dt;
      if (_vy > 0 && position.y >= _restY) {
        position.y = _restY;
        _landed = true;
      }
    }
  }

  void collect() {
    collected = true;
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;
    if (_landed) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(size.x / 2, size.y), width: size.x * 0.9, height: 4),
        Paint()..color = Colors.black.withOpacity(0.25),
      );
    }
    switch (type) {
      case PotionType.badziew:
        _renderBadziew(canvas);
      case PotionType.spoko:
        _renderSpoko(canvas);
      case PotionType.superowa:
        _renderSuper(canvas);
    }
  }

  // Junk: small squat cracked bottle, murky half-empty sludge, crooked cork,
  // stink lines.
  void _renderBadziew(Canvas canvas) {
    final w = size.x, h = size.y;

    for (int i = 0; i < 2; i++) {
      final t = (_age * 0.7 + i * 0.5) % 1.0;
      final x0 = w * (0.3 + i * 0.4);
      final y0 = 2 - t * 10;
      final stink = ui.Path()..moveTo(x0, y0 + 6);
      for (double s = 1; s <= 6; s++) {
        stink.lineTo(x0 + sin(_age * 6 + s + i * 2) * 1.6, y0 + 6 - s);
      }
      canvas.drawPath(
        stink,
        Paint()
          ..color = const Color(0xFF9BB03A).withOpacity((1 - t) * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    final body = RRect.fromLTRBR(1, 9, w - 1, h, const Radius.circular(4));
    final glass = ui.Path.combine(
      ui.PathOperation.union,
      ui.Path()..addRRect(body),
      ui.Path()..addRect(Rect.fromLTRB(w * 0.34, 4, w * 0.66, 10)),
    );
    canvas.drawPath(glass, Paint()..color = const Color(0xFFCFD3B8).withOpacity(0.35));

    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(Rect.fromLTRB(0, h * 0.58, w, h), Paint()..color = type.color);
    canvas.drawRect(Rect.fromLTRB(0, h - 4, w, h), Paint()..color = const Color(0xFF4A3B12));
    for (int i = 0; i < 3; i++) {
      final t = (_age * 0.4 + i * 0.33) % 1.0;
      canvas.drawCircle(
        Offset(4 + i * 5.0, h - 3 - t * h * 0.38),
        1.0,
        Paint()..color = const Color(0xFF3B4210).withOpacity(0.8),
      );
    }
    canvas.restore();

    canvas.drawPath(
      glass,
      Paint()
        ..color = const Color(0xFF5B5A44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      ui.Path()
        ..moveTo(w * 0.72, 11)
        ..lineTo(w * 0.6, 14)
        ..lineTo(w * 0.75, 16.5)
        ..lineTo(w * 0.63, 19.5),
      Paint()
        ..color = const Color(0xFF3F3E2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    canvas.save();
    canvas.translate(w / 2, 4);
    canvas.rotate(-0.4);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w * 0.4, height: 5),
      Paint()..color = const Color(0xFF8B6B3D),
    );
    canvas.restore();
  }

  // Decent: round flask of red healing liquid with a heart, soft pulsing glow.
  void _renderSpoko(Canvas canvas) {
    final w = size.x, h = size.y;
    final r = w / 2 - 1;
    final c = Offset(w / 2, h - r - 1);
    final pulse = 0.5 + 0.5 * sin(_age * 3);

    canvas.drawCircle(c, r + 5 + pulse * 2, Paint()..color = type.color.withOpacity(0.15 + 0.12 * pulse));

    final bulb = ui.Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final glass = ui.Path.combine(
      ui.PathOperation.union,
      bulb,
      ui.Path()..addRect(Rect.fromLTRB(w * 0.36, 4, w * 0.64, c.dy - r + 3)),
    );
    canvas.drawPath(glass, Paint()..color = Colors.white.withOpacity(0.25));

    canvas.save();
    canvas.clipPath(bulb);
    final level = c.dy - r * 0.35 + sin(_age * 2.5) * 0.8;
    canvas.drawRect(Rect.fromLTRB(0, level, w, h), Paint()..color = type.color);
    canvas.drawRect(Rect.fromLTRB(0, level, w, level + 1.5), Paint()..color = Colors.white.withOpacity(0.5));
    canvas.restore();

    _heart(canvas, Offset(c.dx, c.dy + r * 0.3), r * 0.5, Colors.white.withOpacity(0.95));

    canvas.drawPath(
      glass,
      Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 2.5),
      pi * 1.1,
      pi * 0.35,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.32, 0, w * 0.68, 5, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFFB07A44),
    );
  }

  // Super: big ornate bottle, shimmering golden-rainbow liquid, star, golden
  // cap with a gem, strong aura and orbiting sparkles.
  void _renderSuper(Canvas canvas) {
    final w = size.x, h = size.y;
    final pulse = 0.5 + 0.5 * sin(_age * 4);
    final center = Offset(w / 2, h * 0.62);

    canvas.drawCircle(center, w * 0.75 + pulse * 3, Paint()..color = const Color(0xFFFFD54A).withOpacity(0.16 + 0.12 * pulse));
    canvas.drawCircle(center, w * 0.55, Paint()..color = const Color(0xFFFFF3B0).withOpacity(0.18));

    final body = ui.Path()
      ..moveTo(w * 0.36, 11)
      ..lineTo(w * 0.64, 11)
      ..quadraticBezierTo(w, 14, w - 1, h * 0.6)
      ..quadraticBezierTo(w - 1, h, w / 2, h)
      ..quadraticBezierTo(1, h, 1, h * 0.6)
      ..quadraticBezierTo(0, 14, w * 0.36, 11)
      ..close();
    final glass = ui.Path.combine(
      ui.PathOperation.union,
      body,
      ui.Path()..addRect(Rect.fromLTRB(w * 0.36, 5, w * 0.64, 12)),
    );
    canvas.drawPath(glass, Paint()..color = Colors.white.withOpacity(0.25));

    canvas.save();
    canvas.clipPath(body);
    final liquid = Rect.fromLTRB(0, 14, w, h);
    final shift = (_age * 0.6) % 2.0;
    canvas.drawRect(
      liquid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(-1 + shift, -1),
          end: Alignment(1 + shift, 1),
          colors: const [Color(0xFFFFE066), Color(0xFFFF9F1C), Color(0xFFFF4FD8), Color(0xFFFFE066)],
          tileMode: TileMode.mirror,
        ).createShader(liquid),
    );
    canvas.restore();

    _star(canvas, Offset(w / 2, h * 0.66), 6.5, 2.8, sin(_age * 2) * 0.25, Colors.white);

    canvas.drawPath(
      glass,
      Paint()
        ..color = const Color(0xFFFFE9A0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.3, 10, w * 0.7, 13, const Radius.circular(1.5)),
      Paint()..color = const Color(0xFFE0A800),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.33, 0, w * 0.67, 6, const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFC107),
    );
    canvas.drawCircle(Offset(w / 2, 3), 1.6, Paint()..color = const Color(0xFFE91E63));

    for (int i = 0; i < 4; i++) {
      final a = _age * 2 + i * pi / 2;
      _sparkle(
        canvas,
        Offset(center.dx + cos(a) * w * 0.7, center.dy + sin(a) * h * 0.45),
        2.5 + sin(_age * 6 + i) * 1.0,
        Colors.white,
      );
    }
  }
}

/// Text that pops up after drinking a potion: "badziew" sags and wobbles,
/// "spoko" floats up, "super" shoots up in gold with sparkles.
class PotionPopup extends PositionComponent {
  final PotionType type;
  double _t = 0;
  static const _duration = 1.4;

  late final TextPainter _outline;
  late final TextPainter _fill;

  PotionPopup({required this.type, required Vector2 pos}) {
    position = pos;
    priority = 100;
  }

  @override
  Future<void> onLoad() async {
    final style = TextStyle(fontSize: type.fontSize, fontWeight: FontWeight.w900, letterSpacing: 1);
    _outline = TextPainter(
      text: TextSpan(
        text: type.popupText,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeJoin = StrokeJoin.round
            ..color = type.outline,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final fill = Paint()..color = type.color;
    if (type == PotionType.superowa) {
      fill.shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF59D), Color(0xFFFFC107), Color(0xFFFF6F00)],
      ).createShader(Rect.fromLTWH(0, 0, _outline.width, _outline.height));
    }
    _fill = TextPainter(
      text: TextSpan(text: type.popupText, style: style.copyWith(foreground: fill)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final p = (_t / _duration).clamp(0.0, 1.0);
    final rise = Curves.easeOut.transform(p);
    var scale = 0.3 + 0.7 * Curves.elasticOut.transform((_t / 0.4).clamp(0.0, 1.0));
    double dy;
    double rotation = 0;
    switch (type) {
      case PotionType.badziew:
        dy = -16 * rise + 14 * p * p; // rises a bit, then sags
        rotation = sin(_t * 22) * 0.12 * (1 - p);
      case PotionType.spoko:
        dy = -34 * rise;
      case PotionType.superowa:
        dy = -48 * rise;
        scale *= 1 + 0.06 * sin(_t * 14);
    }
    final opacity = p < 0.65 ? 1.0 : 1 - (p - 0.65) / 0.35;
    final offset = Offset(-_fill.width / 2, -_fill.height);

    canvas.save();
    canvas.translate(0, dy);
    canvas.rotate(rotation);
    canvas.scale(scale);
    canvas.saveLayer(
      Rect.fromLTWH(offset.dx - 8, offset.dy - 8, _fill.width + 16, _fill.height + 16),
      Paint()..color = Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
    );
    _outline.paint(canvas, offset);
    _fill.paint(canvas, offset);
    if (type == PotionType.superowa) {
      for (int i = 0; i < 5; i++) {
        final a = _t * 3 + i * 2 * pi / 5;
        _sparkle(
          canvas,
          Offset(cos(a) * (_fill.width * 0.6), offset.dy + _fill.height / 2 + sin(a) * _fill.height * 0.7),
          3 + sin(_t * 10 + i) * 1.2,
          const Color(0xFFFFF59D),
        );
      }
    }
    canvas.restore();
    canvas.restore();
  }
}

void _heart(Canvas canvas, Offset c, double s, Color color) {
  final paint = Paint()..color = color;
  canvas.drawCircle(Offset(c.dx - s * 0.5, c.dy - s * 0.3), s * 0.55, paint);
  canvas.drawCircle(Offset(c.dx + s * 0.5, c.dy - s * 0.3), s * 0.55, paint);
  canvas.drawPath(
    ui.Path()
      ..moveTo(c.dx - s, c.dy - s * 0.1)
      ..lineTo(c.dx, c.dy + s)
      ..lineTo(c.dx + s, c.dy - s * 0.1)
      ..close(),
    paint,
  );
}

void _star(Canvas canvas, Offset c, double outer, double inner, double rotation, Color color) {
  final path = ui.Path();
  for (int i = 0; i < 10; i++) {
    final r = i.isEven ? outer : inner;
    final a = rotation - pi / 2 + i * pi / 5;
    final p = Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  canvas.drawPath(path, Paint()..color = color);
}

void _sparkle(Canvas canvas, Offset c, double s, Color color) {
  final paint = Paint()..color = color.withOpacity(0.9);
  canvas.drawPath(
    ui.Path()
      ..moveTo(c.dx, c.dy - s)
      ..lineTo(c.dx + s * 0.25, c.dy)
      ..lineTo(c.dx, c.dy + s)
      ..lineTo(c.dx - s * 0.25, c.dy)
      ..close()
      ..moveTo(c.dx - s, c.dy)
      ..lineTo(c.dx, c.dy + s * 0.25)
      ..lineTo(c.dx + s, c.dy)
      ..lineTo(c.dx, c.dy - s * 0.25)
      ..close(),
    paint,
  );
}
