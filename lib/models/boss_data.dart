import 'dart:math';

class BossData {
  final String id;
  final String name;
  final String spritePath;
  final int hp;
  final double spriteScale;

  const BossData({
    required this.id,
    required this.name,
    required this.spritePath,
    required this.hp,
    this.spriteScale = 1.0,
  });

  static const List<BossData> allBosses = [
    BossData(id: 'duch', name: 'Duch Guwniak', spritePath: 'assets/sprites/bosses/boss_duch.png', hp: 15, spriteScale: 1.1),
    BossData(id: 'roslinka', name: 'Zła Roślinka', spritePath: 'assets/sprites/bosses/boss_roslinka.png', hp: 18, spriteScale: 1.2),
    BossData(id: 'patapon', name: 'Boss Patapon', spritePath: 'assets/sprites/bosses/boss_patapon.png', hp: 20, spriteScale: 1.0),
    BossData(id: 'bokser', name: 'Fioletowy Bokser', spritePath: 'assets/sprites/bosses/boss_bokser.png', hp: 22, spriteScale: 1.2),
    BossData(id: 'gasienica', name: 'Gąsienica', spritePath: 'assets/sprites/bosses/boss_gasienica.png', hp: 17, spriteScale: 0.9),
    BossData(id: 'magidonga', name: 'Magidonga', spritePath: 'assets/sprites/bosses/boss_magidonga.png', hp: 20, spriteScale: 1.0),
    BossData(id: 'osmiornica', name: 'Ośmiornica', spritePath: 'assets/sprites/bosses/boss_osmiornica.png', hp: 19, spriteScale: 1.0),
    BossData(id: 'drzewo', name: 'Straszydrzewo', spritePath: 'assets/sprites/bosses/boss_drzewo.png', hp: 25, spriteScale: 1.3),
    BossData(id: 'ludzik', name: 'Zły Ludzik', spritePath: 'assets/sprites/bosses/boss_ludzik.png', hp: 16, spriteScale: 1.1),
    BossData(id: 'zolw', name: 'Żółw Morski', spritePath: 'assets/sprites/bosses/boss_zolw.png', hp: 23, spriteScale: 1.0),
  ];

  static final _rng = Random();
  static final List<BossData> _deck = [];

  static BossData next() {
    if (_deck.isEmpty) {
      _deck.addAll(allBosses);
      _deck.shuffle(_rng);
    }
    return _deck.removeLast();
  }
}
