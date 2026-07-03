import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/pata_game.dart';
import '../models/patapon_data.dart';

class GameScreen extends StatefulWidget {
  final PataponData pataponData;
  const GameScreen({super.key, required this.pataponData});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PataGame _game;

  @override
  void initState() {
    super.initState();
    _game = PataGame(pataponData: widget.pataponData);
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
                return Row(
                  children: [
                    // HP hearts
                    Row(
                      children: List.generate(state.maxHp, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            i < state.hp ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                            size: 24,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    // Ammo
                    if (state.ammo > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🌭 ${state.ammo}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Shield
                    if (state.hasShield)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🛡️', style: TextStyle(fontSize: 16)),
                      ),
                    // Active power-up
                    if (state.activePowerUp != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.activePowerUp!,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Coins
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🪙 ${state.coins}',
                        style: const TextStyle(color: Colors.amber, fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Mobile controls
          Positioned(
            bottom: 16,
            left: 16,
            child: Row(
              children: [
                _MobileButton(icon: Icons.arrow_left, onTapDown: () => _game.player.simulateKey(LogicalDirection.left, true), onTapUp: () => _game.player.simulateKey(LogicalDirection.left, false)),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                _MobileButton(icon: Icons.flash_on, onTapDown: () => _game.player.simulateKey(LogicalDirection.attack, true), onTapUp: () => _game.player.simulateKey(LogicalDirection.attack, false)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum LogicalDirection { left, right, up, attack }

class _MobileButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;

  const _MobileButton({required this.icon, required this.onTapDown, required this.onTapUp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38, width: 2),
        ),
        child: Icon(icon, color: Colors.white70, size: 28),
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
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GAME OVER', style: TextStyle(fontSize: 40, color: Colors.red, fontWeight: FontWeight.bold)),
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('LEVEL COMPLETE!', style: TextStyle(fontSize: 36, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Monety: ${game.stateNotifier.value.coins}',
              style: const TextStyle(fontSize: 20, color: Colors.amber),
            ),
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
