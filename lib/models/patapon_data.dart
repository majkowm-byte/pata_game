import 'package:flutter/material.dart';

class PataponData {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final double speed;
  final double jumpForce;
  final int maxHp;
  final double attackRange;
  final int attackDamage;
  final Color themeColor;
  final String specialAbility;

  const PataponData({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.speed,
    required this.jumpForce,
    required this.maxHp,
    required this.attackRange,
    required this.attackDamage,
    required this.themeColor,
    required this.specialAbility,
  });

  static const List<PataponData> allPatapons = [
    PataponData(
      id: 'drewniak',
      name: 'Drewniak',
      description: 'Tank z domkiem na głowie. Wolny ale wytrzymały.',
      imagePath: 'patapons_draw/Drewniak.jpeg',
      speed: 140,
      jumpForce: 320,
      maxHp: 6,
      attackRange: 40,
      attackDamage: 2,
      themeColor: Color(0xFF8B4513),
      specialAbility: 'Wytrzymałość — przyjmuje o 50% mniej obrażeń',
    ),
    PataponData(
      id: 'gaciar',
      name: 'Gaciar',
      description: 'Szybki świniak w klapkach. Ślizga się po platformach.',
      imagePath: 'patapons_draw/Gaciar.jpeg',
      speed: 220,
      jumpForce: 350,
      maxHp: 3,
      attackRange: 30,
      attackDamage: 1,
      themeColor: Color(0xFFFF69B4),
      specialAbility: 'Ślizg — podwójny dash na ziemi',
    ),
    PataponData(
      id: 'grillak',
      name: 'Grillak',
      description: 'Mistrz grilla. Ciska kiełbachami jak pociskami.',
      imagePath: 'patapons_draw/Grillak.jpeg',
      speed: 170,
      jumpForce: 330,
      maxHp: 4,
      attackRange: 200,
      attackDamage: 1,
      themeColor: Color(0xFF4169E1),
      specialAbility: 'Kiełbacho-strzelec — rzuca kiełbachy (5 szt. amunicji)',
    ),
    PataponData(
      id: 'kundziak',
      name: 'Kundziak',
      description: 'Techno-patapon z telefonem. Zamraża wrogów na chwilę.',
      imagePath: 'patapons_draw/Kundziak.jpeg',
      speed: 160,
      jumpForce: 330,
      maxHp: 3,
      attackRange: 150,
      attackDamage: 1,
      themeColor: Color(0xFF4682B4),
      specialAbility: 'Hack — zamraża wrogów na 2 sekundy',
    ),
    PataponData(
      id: 'silny',
      name: 'Silny',
      description: 'Ognisty wojownik. Największy damage w grze.',
      imagePath: 'patapons_draw/Silny.jpeg',
      speed: 160,
      jumpForce: 340,
      maxHp: 4,
      attackRange: 50,
      attackDamage: 3,
      themeColor: Color(0xFFFF4500),
      specialAbility: 'Ognisty miecz — podpala wrogów na 3 sekundy',
    ),
    PataponData(
      id: 'tutek',
      name: 'Tutek',
      description: 'Zbalansowany wojownik. Dobry na start.',
      imagePath: 'patapons_draw/Tutek.jpeg',
      speed: 180,
      jumpForce: 340,
      maxHp: 4,
      attackRange: 45,
      attackDamage: 2,
      themeColor: Color(0xFFDAA520),
      specialAbility: 'Musztardowy atak — spowolnia trafionego wroga',
    ),
    PataponData(
      id: 'wlosatol',
      name: 'Włosatol',
      description: 'Fryzjerski support. Odpycha wrogów dmuchawą.',
      imagePath: 'patapons_draw/Włosatol.jpeg',
      speed: 170,
      jumpForce: 330,
      maxHp: 3,
      attackRange: 100,
      attackDamage: 1,
      themeColor: Color(0xFFFF1493),
      specialAbility: 'Podmuch — odpycha wrogów suszarką',
    ),
    PataponData(
      id: 'zieloniak',
      name: 'Zieloniak',
      description: 'Obrońca z tarczą. Blokuje ataki frontalne.',
      imagePath: 'patapons_draw/Zieloniak.jpeg',
      speed: 155,
      jumpForce: 320,
      maxHp: 5,
      attackRange: 45,
      attackDamage: 2,
      themeColor: Color(0xFF228B22),
      specialAbility: 'Tarcza — blokuje 1 atak co 5 sekund',
    ),
  ];
}
