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
    description: 'Nieśmiertelność przez 30 sekund',
    color: Color(0xFF7B68EE),
    duration: 30,
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
  ),
  angelProtection(
    label: 'Anielska Ochrona',
    description: 'Ratuje raz od śmierci lub przepaści',
    color: Color(0xFF1a1a1a),
    duration: 0,
    icon: '💛',
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
