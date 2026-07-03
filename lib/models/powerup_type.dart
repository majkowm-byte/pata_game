import 'package:flutter/material.dart';

enum PowerUpType {
  extraAmmo(
    label: 'Amunicja +5',
    description: 'Dodatkowe pociski do rzucania',
    color: Color(0xFFFF6B35),
    duration: 0,
    icon: '🎯',
  ),
  speedBoost(
    label: 'Turbo',
    description: 'Szybkość x1.5 przez 8 sekund',
    color: Color(0xFF00BFFF),
    duration: 8,
    icon: '⚡',
  ),
  shield(
    label: 'Tarcza',
    description: 'Absorbujesz 1 trafienie',
    color: Color(0xFF7B68EE),
    duration: 0,
    icon: '🛡️',
  ),
  bigWeapon(
    label: 'Wielka Broń',
    description: 'Podwójny zasięg ataku przez 10 sekund',
    color: Color(0xFFFF4500),
    duration: 10,
    icon: '⚔️',
  ),
  heal(
    label: 'Kiełbacha Lecznicza',
    description: 'Odnawia 2 HP',
    color: Color(0xFF32CD32),
    duration: 0,
    icon: '🌭',
  );

  final String label;
  final String description;
  final Color color;
  final double duration;
  final String icon;

  const PowerUpType({
    required this.label,
    required this.description,
    required this.color,
    required this.duration,
    required this.icon,
  });
}
