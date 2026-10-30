import 'dart:math' show min, pi;
import 'package:flutter/material.dart';
import '../game/pata_game.dart';

/// Level-up screen. The game is already paused when it appears; then the
/// collected coin grows and fades out while the screen smoothly goes black,
/// and the upgrade cards pop in one after another.
class LevelUpOverlay extends StatefulWidget {
  final PataGame game;

  /// Screen position of the coin that triggered the level-up.
  final Offset coin;

  const LevelUpOverlay({super.key, required this.game, required this.coin});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> with TickerProviderStateMixin {
  // Intro timeline (fractions of _intro):
  //   0.00-0.35  coin grows and fades out, screen fades to black
  //   0.30-0.58  title pops in
  //   0.42-1.00  cards pop in one after another
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  late final AnimationController _outro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  late final Animation<double> _coin =
      CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.35, curve: Curves.easeOut));
  late final Animation<double> _dim =
      CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.35, curve: Curves.easeInOut));
  late final Animation<double> _title =
      CurvedAnimation(parent: _intro, curve: const Interval(0.30, 0.58, curve: Curves.elasticOut));
  late final Animation<double> _subtitle =
      CurvedAnimation(parent: _intro, curve: const Interval(0.40, 0.55, curve: Curves.easeOut));
  late final List<Animation<double>> _cards = [
    for (int i = 0; i < 3; i++)
      CurvedAnimation(
        parent: _intro,
        curve: Interval(0.42 + i * 0.10, min(1.0, 0.80 + i * 0.10), curve: Curves.elasticOut),
      ),
  ];

  // Cards only react once they're on screen, so taps meant for the game
  // controls right before the level-up don't pick an upgrade by accident.
  bool get _ready => _intro.value >= 0.75 && !_choosing;
  bool _choosing = false;

  Future<void> _choose(String type) async {
    if (!_ready) return;
    setState(() => _choosing = true);
    await _outro.forward();
    widget.game.applyUpgrade(type);
  }

  @override
  void dispose() {
    _intro.dispose();
    _outro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.game.stateNotifier.value;
    final weaponNext = state.weaponLevel + 1;
    final speedNext = state.speedLevel + 1;
    final jumpNext = state.jumpLevel + 1;

    const weaponLabels = ['150%', '200%', '250%', '300%'];
    const speedLabels = ['130%', '160%', '190%', '210%'];
    const jumpLabels = ['130%', '160%', '190%', '210%'];

    final canWeapon = weaponNext <= weaponLabels.length;
    final canSpeed = speedNext <= speedLabels.length;
    final canJump = jumpNext <= jumpLabels.length;

    final cards = [
      _UpgradeCard(
        title: 'BIG HIT',
        icon: Icons.gavel,
        level: weaponNext,
        description: canWeapon ? weaponLabels[weaponNext - 1] : 'MAX',
        gradient: const [Color(0xFFFF6B00), Color(0xFFFF2200)],
        enabled: canWeapon,
        onTap: canWeapon ? () => _choose('weapon') : null,
      ),
      _UpgradeCard(
        title: 'SPEED',
        icon: Icons.speed,
        level: speedNext,
        description: canSpeed ? speedLabels[speedNext - 1] : 'MAX',
        gradient: const [Color(0xFF00BCD4), Color(0xFF0077FF)],
        enabled: canSpeed,
        onTap: canSpeed ? () => _choose('speed') : null,
      ),
      _UpgradeCard(
        title: 'JUMP',
        icon: Icons.arrow_upward,
        level: jumpNext,
        description: canJump ? jumpLabels[jumpNext - 1] : 'MAX',
        gradient: const [Color(0xFF4CAF50), Color(0xFF00C853)],
        enabled: canJump,
        onTap: canJump ? () => _choose('jump') : null,
      ),
    ];

    return AnimatedBuilder(
      animation: Listenable.merge([_intro, _outro]),
      builder: (context, _) {
        final fadeOut = 1.0 - _outro.value;
        return Stack(
          children: [
            // Black fade. Opaque to touches so nothing underneath reacts.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ColoredBox(color: Colors.black.withOpacity(0.9 * _dim.value * fadeOut)),
              ),
            ),
            if (_coin.value < 1)
              Positioned(
                left: widget.coin.dx - 15,
                top: widget.coin.dy - 15,
                width: 30,
                height: 30,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 1 - _coin.value,
                    child: Transform.scale(
                      scale: 1 + 4 * _coin.value,
                      child: const CustomPaint(painter: _CoinPainter()),
                    ),
                  ),
                ),
              ),
            Center(
              child: IgnorePointer(
                ignoring: !_ready,
                child: Opacity(
                  opacity: fadeOut,
                  child: Transform.scale(
                    scale: 1 - 0.1 * _outro.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: _title.value,
                          child: const Text(
                            'POWER UP!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD700),
                              shadows: [Shadow(color: Color(0xFFFF8C00), blurRadius: 12)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: _subtitle.value,
                          child: Text(
                            'Koszt: ${state.nextUpgradeCost} monet',
                            style: const TextStyle(color: Colors.amber, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 12),
                              Transform.rotate(
                                angle: (1 - _cards[i].value) * pi / 8,
                                child: Transform.scale(
                                  scale: _cards[i].value,
                                  child: Opacity(
                                    opacity: _cards[i].value.clamp(0.0, 1.0),
                                    child: cards[i],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Same look as the in-game Coin, at the same size (centered in its box).
class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, 12, Paint()..color = const Color(0xFFFFD700).withOpacity(0.15));
    canvas.drawCircle(c, 9, Paint()..color = const Color(0xFFFFD700));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 9),
      -pi * 0.8,
      pi * 0.6,
      false,
      Paint()
        ..color = const Color(0xFFFFE44D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c,
      9,
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(c, 4.5, Paint()..color = const Color(0xFFDAA520));
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) => false;
}

class _UpgradeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int level;
  final String description;
  final List<Color> gradient;
  final bool enabled;
  final VoidCallback? onTap;

  const _UpgradeCard({
    required this.title,
    required this.icon,
    required this.level,
    required this.description,
    required this.gradient,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: enabled
              ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: enabled ? null : Colors.grey[800],
          border: Border.all(
            color: enabled ? Colors.white.withOpacity(0.4) : Colors.grey[600]!,
            width: 2,
          ),
          boxShadow: enabled
              ? [BoxShadow(color: gradient[0].withOpacity(0.4), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: enabled ? Colors.white : Colors.grey, size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lv.$level',
                style: TextStyle(
                  color: enabled ? Colors.white70 : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: enabled ? const Color(0xFFFFD700) : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
