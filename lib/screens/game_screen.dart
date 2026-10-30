import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/pata_game.dart';
import '../game/levels/level.dart';
import '../models/patapon_data.dart';
import 'level_up_overlay.dart';

class GameScreen extends StatefulWidget {
  final PataponData pataponData;
  final bool shieldMode;
  const GameScreen({super.key, required this.pataponData, this.shieldMode = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PataGame _game;

  @override
  void initState() {
    super.initState();
    _game = PataGame(pataponData: widget.pataponData, shieldMode: widget.shieldMode);
  }

  @override
  void dispose() {
    _game.pauseEngine();
    _game.onRemove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<PataGame>(
            game: _game,
            overlayBuilderMap: {
              'GameOver': (context, game) => _GameOverOverlay(game: game),
              'LevelComplete': (context, game) => _LevelCompleteOverlay(game: game),
              'GameWon': (context, game) => _GameWonOverlay(game: game),
              'BossIntro': (context, game) => _BossIntroOverlay(game: game),
            },
          ),
          // Screen flash
          ValueListenableBuilder<GameState>(
            valueListenable: _game.stateNotifier,
            builder: (context, state, _) {
              if (state.screenFlash > 0) {
                return Positioned.fill(
                  child: IgnorePointer(
                    child: Container(color: Colors.white.withOpacity(0.4)),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // HUD
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: ValueListenableBuilder<GameState>(
              valueListenable: _game.stateNotifier,
              builder: (context, state, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lv.${state.currentLevel}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (state.shieldMode)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield, color: Colors.white, size: 14),
                                SizedBox(width: 2),
                                Text('TARCZA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        Row(
                          children: List.generate(state.maxHp, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                i < state.hp ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                                size: 20,
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        // Weapon size
                        if (state.weaponLevel > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '⚔️ ${(state.weaponMultiplier * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (state.speedLevel > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'SPD+${state.speedLevel}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        if (state.jumpLevel > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'JMP+${state.jumpLevel}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: Text('🪙 ${state.coins}/${state.nextUpgradeCost}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (state.ammo > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                            child: Text('🌭 ${state.ammo}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: Text('⚡ ${state.lightnings}', style: const TextStyle(color: Color(0xFF00BFFF), fontSize: 12)),
                        ),
                        if (state.shieldTimer > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                            child: Text('🛡️ ${state.shieldTimer.ceil()}s', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        if (state.hasShield && state.shieldTimer <= 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                            child: const Text('🛡️', style: TextStyle(fontSize: 12)),
                          ),
                        if (state.activePowerUp != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
                            child: Text(state.activePowerUp!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          // Power-up toast
          ValueListenableBuilder<GameState>(
            valueListenable: _game.stateNotifier,
            builder: (context, state, _) {
              if (state.powerUpToast == null) return const SizedBox.shrink();
              return Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.6), width: 2),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: Text(
                      state.powerUpToast!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Mobile controls
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                _MobileButton(icon: Icons.arrow_left, onTapDown: () => _game.player.simulateKey(LogicalDirection.left, true), onTapUp: () => _game.player.simulateKey(LogicalDirection.left, false)),
                const SizedBox(width: 11),
                _MobileButton(icon: Icons.arrow_right, onTapDown: () => _game.player.simulateKey(LogicalDirection.right, true), onTapUp: () => _game.player.simulateKey(LogicalDirection.right, false)),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              children: [
                _MobileButton(icon: Icons.arrow_upward, onTapDown: () => _game.player.simulateKey(LogicalDirection.up, true), onTapUp: () => _game.player.simulateKey(LogicalDirection.up, false)),
                const SizedBox(width: 11),
                _MobileButton(icon: Icons.close, label: 'ATAK', customIcon: const Text('⚔', style: TextStyle(fontSize: 22)), onTapDown: () => _game.player.simulateKey(LogicalDirection.attack, true), onTapUp: () => _game.player.simulateKey(LogicalDirection.attack, false)),
                const SizedBox(width: 11),
                _MobileButton(icon: Icons.bolt, label: '⚡', color: const Color(0xFF00BFFF), onTapDown: () => _game.player.simulateKey(LogicalDirection.offhand, true), onTapUp: () => _game.player.simulateKey(LogicalDirection.offhand, false)),
              ],
            ),
          ),
          // Top-right buttons
          Positioned(
            top: 60,
            right: 8,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showCharacterSwitch(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFDAA520), Color(0xFFB8860B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0xFFFFF8DC), width: 2),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.autorenew, color: Color(0xFF3E2723), size: 26),
                  ),
                ),
                const SizedBox(width: 6),
                _SmallButton(
                  icon: Icons.exit_to_app,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Level-up screen goes last, above the HUD and the controls, so the
          // fade to black covers the whole screen and nothing under it reacts.
          ValueListenableBuilder<Offset?>(
            valueListenable: _game.levelUpCoin,
            builder: (context, coin, _) => coin == null
                ? const SizedBox.shrink()
                : Positioned.fill(child: LevelUpOverlay(game: _game, coin: coin)),
          ),
        ],
      ),
    );
  }

  void _showCharacterSwitch(BuildContext context) {
    _game.paused = true;
    PataponData selected = _game.pataponData;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isCurrent = selected.id == _game.pataponData.id;
            return AlertDialog(
              backgroundColor: const Color(0xFF1a0533),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              title: const Text('ZMIEŃ BOHATERA', style: TextStyle(color: Colors.white, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: PataponData.allPatapons.length,
                          itemBuilder: (context, index) {
                            final p = PataponData.allPatapons[index];
                            final isSelected = p.id == selected.id;
                            return GestureDetector(
                              onTap: () => setDialogState(() => selected = p),
                              child: Container(
                                width: 64,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? p.themeColor.withOpacity(0.4) : Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? p.themeColor : Colors.white24, width: isSelected ? 2 : 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.asset(p.imagePath, width: 40, height: 40, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: p.themeColor, child: const Icon(Icons.person, color: Colors.white, size: 18))),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(p.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 8), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(selected.imagePath, width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: selected.themeColor, child: const Icon(Icons.person, color: Colors.white, size: 24))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selected.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: selected.themeColor)),
                                Text(selected.description, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                const SizedBox(height: 2),
                                Text('★ ${selected.specialAbility}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _switchHeartsRow(selected.maxHp),
                      _switchBar('Szybkość', selected.speed / 220, Colors.blue),
                      _switchBar('Skok', selected.jumpForce / 420, Colors.orange),
                      _switchBar('Zasięg', selected.attackRange / 200, Colors.green),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFFF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00BFFF).withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('⚡ ${selected.offhandName}', style: const TextStyle(color: Color(0xFF00BFFF), fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(selected.offhandDescription, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.grey.shade700 : selected.themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      if (!isCurrent) _game.switchCharacter(selected);
                      Navigator.of(ctx).pop();
                      _game.paused = false;
                    },
                    child: Text(
                      isCurrent ? 'OK' : 'WYBIERZ',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget _switchHeartsRow(int hearts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          const SizedBox(width: 55, child: Text('Życie', style: TextStyle(color: Colors.white70, fontSize: 10))),
          ...List.generate(hearts, (_) => const Padding(padding: EdgeInsets.only(right: 1), child: Icon(Icons.favorite, color: Colors.red, size: 12))),
        ],
      ),
    );
  }

  static Widget _switchBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(width: 55, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: value.clamp(0, 1), backgroundColor: Colors.white12, color: color, minHeight: 6),
            ),
          ),
        ],
      ),
    );
  }
}

enum LogicalDirection { left, right, up, attack, offhand }

class _MobileButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final Widget? customIcon;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _MobileButton({required this.icon, this.label, this.color, this.customIcon, required this.onTapDown, required this.onTapUp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: color?.withOpacity(0.3) ?? Colors.white24,
          shape: BoxShape.circle,
          border: Border.all(color: color?.withOpacity(0.6) ?? Colors.white38, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customIcon != null) customIcon! else Icon(icon, color: color ?? Colors.white70, size: label != null ? 24 : 34),
            if (label != null)
              Text(label!, style: TextStyle(color: color ?? Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}


class _SmallButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final PataGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME OVER', style: TextStyle(fontSize: 40, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              game.currentLevel > 0 ? 'Cofasz się do poziomu ${game.currentLevel}' : '',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('GameOver');
                game.restartLevel();
              },
              child: const Text('SPRÓBUJ PONOWNIE', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('MENU', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCompleteOverlay extends StatelessWidget {
  final PataGame game;
  const _LevelCompleteOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    final nextLevel = game.currentLevel + 1;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('LEVEL COMPLETE!', style: TextStyle(fontSize: 36, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Monety: ${game.stateNotifier.value.coins}',
              style: const TextStyle(fontSize: 20, color: Colors.amber),
            ),
            const SizedBox(height: 4),
            Text(
              'Następny: ${GameLevel.nameFor(nextLevel)}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => game.nextLevel(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('NASTĘPNY LEVEL', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('MENU', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameWonOverlay extends StatelessWidget {
  final PataGame game;
  const _GameWonOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GRATULACJE!', style: TextStyle(fontSize: 40, color: Colors.amber, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ukończyłeś wszystkie levele!', style: TextStyle(fontSize: 20, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Monety: ${game.stateNotifier.value.coins}', style: const TextStyle(fontSize: 20, color: Colors.amber)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('WRÓĆ DO MENU', style: TextStyle(color: Colors.white70, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BossIntroOverlay extends StatefulWidget {
  final PataGame game;
  const _BossIntroOverlay({required this.game});

  @override
  State<_BossIntroOverlay> createState() => _BossIntroOverlayState();
}

class _BossIntroOverlayState extends State<_BossIntroOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _nameScale;
  late Animation<double> _flashOpacity;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2, curve: Curves.easeIn)),
    );
    _nameScale = Tween(begin: 3.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.25, 0.5, curve: Curves.elasticOut)),
    );
    _flashOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 0.8, curve: Curves.easeIn)),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.85, 1.0, curve: Curves.easeOut)),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.game.finishBossIntro();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            // Black background
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(_fadeIn.value * _fadeOut.value),
              ),
            ),
            // Boss name
            if (_controller.value > 0.25)
              Center(
                child: Transform.scale(
                  scale: _nameScale.value,
                  child: Opacity(
                    opacity: _fadeOut.value,
                    child: const Text(
                      'BOSS!',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        shadows: [
                          Shadow(color: Colors.redAccent, blurRadius: 20),
                          Shadow(color: Colors.orange, blurRadius: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // White flash
            if (_controller.value > 0.7)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withOpacity(_flashOpacity.value * _fadeOut.value * 0.8),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
