import 'dart:math' show Random;
import 'package:flutter/material.dart';

/// Healing potions dropped by fat (crowned) mobs.
enum PotionType {
  badziew(
    heal: 1,
    popupText: 'badziew',
    color: Color(0xFF8A9A2C),
    outline: Color(0xFF3B2F12),
    fontSize: 18,
    width: 18,
    height: 24,
  ),
  spoko(
    heal: 3,
    popupText: 'spoko',
    color: Color(0xFFFF4D6D),
    outline: Color(0xFF5C0A1A),
    fontSize: 22,
    width: 22,
    height: 28,
  ),
  superowa(
    heal: null, // full HP
    popupText: 'super',
    color: Color(0xFFFFD54A),
    outline: Color(0xFF6B2A00),
    fontSize: 28,
    width: 26,
    height: 34,
  );

  /// HP restored; null heals to max HP.
  final int? heal;
  final String popupText;
  final Color color;
  final Color outline;
  final double fontSize;
  final double width;
  final double height;

  const PotionType({
    required this.heal,
    required this.popupText,
    required this.color,
    required this.outline,
    required this.fontSize,
    required this.width,
    required this.height,
  });

  static PotionType random(Random rng) => values[rng.nextInt(values.length)];
}
