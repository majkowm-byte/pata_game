import 'package:flutter/material.dart';
import '../models/patapon_data.dart';
import '../game/audio/retro_music.dart';
import 'game_screen.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  int _selectedIndex = 0;
  bool _shieldMode = false;
  bool _showOffhandTip = false;

  @override
  void initState() {
    super.initState();
    RetroMusic.instance.init().then((_) => RetroMusic.instance.playMenu());
  }

  @override
  Widget build(BuildContext context) {
    final selected = PataponData.allPatapons[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF1a0533),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'WYBIERZ PATAPONA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            // Character grid
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: PataponData.allPatapons.length,
                itemBuilder: (context, index) {
                  final patapon = PataponData.allPatapons[index];
                  final isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedIndex = index;
                      _showOffhandTip = false;
                    }),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? patapon.themeColor.withOpacity(0.4) : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? patapon.themeColor : Colors.white24,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              patapon.imagePath,
                              width: 48, height: 48, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 48, height: 48, color: patapon.themeColor,
                                child: const Icon(Icons.person, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            patapon.name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Selected character info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Name + description row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            selected.imagePath,
                            width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80, height: 80, color: selected.themeColor,
                              child: const Icon(Icons.person, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.name,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: selected.themeColor),
                              ),
                              Text(selected.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('★ ${selected.specialAbility}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Hearts (life) — show actual count instead of a bar
                    _buildHeartsRow(selected.maxHp),
                    const SizedBox(height: 4),
                    // Stat bars
                    _buildStatBar('Szybkość', selected.speed / 220, Colors.blue),
                    _buildStatBar('Skok', selected.jumpForce / 420, Colors.orange),
                    _buildStatBar('Zasięg', selected.attackRange / 200, Colors.green),
                    const SizedBox(height: 8),
                    // OFFHAND SKILL BUBBLE - always visible
                    GestureDetector(
                      onTap: () => setState(() => _showOffhandTip = !_showOffhandTip),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFFF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00BFFF).withOpacity(0.5), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('⚡', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'OFF-HAND: ${selected.offhandName}',
                                  style: const TextStyle(
                                    color: Color(0xFF00BFFF),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _showOffhandTip ? Icons.expand_less : Icons.expand_more,
                                  color: const Color(0xFF00BFFF),
                                  size: 20,
                                ),
                              ],
                            ),
                            if (_showOffhandTip) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00BFFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  selected.offhandDescription,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom row: start + shield + exit
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 6, bottom: 8),
              child: Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected.themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GameScreen(pataponData: selected, shieldMode: _shieldMode),
                        ),
                      ).then((_) => RetroMusic.instance.playMenu());
                    },
                    child: const Text('START MISJI', style: TextStyle(fontSize: 15, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _shieldMode = !_shieldMode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _shieldMode ? Colors.blue.withOpacity(0.4) : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _shieldMode ? Colors.blue : Colors.white24, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield, color: _shieldMode ? Colors.blue : Colors.white38, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'TARCZA',
                            style: TextStyle(color: _shieldMode ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.exit_to_app, color: Colors.white38, size: 16),
                    label: const Text('WYJŚCIE', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartsRow(int hearts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          const SizedBox(width: 65, child: Text('Życie', style: TextStyle(color: Colors.white70, fontSize: 12))),
          Row(
            children: List.generate(
              hearts,
              (i) => const Padding(
                padding: EdgeInsets.only(right: 3),
                child: Icon(Icons.favorite, color: Colors.red, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('×$hearts', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(width: 65, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                backgroundColor: Colors.white12,
                color: color,
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
