import 'package:flutter/material.dart';

class WeaponRegion {
  final double left;
  final double top;
  final double width;
  final double height;
  final double pivotX;
  final double pivotY;

  const WeaponRegion({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.pivotX = 0.0,
    this.pivotY = 0.5,
  });
}

class PataponData {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String spritePath;
  final String weaponSpritePath;
  final WeaponRegion weaponRegion;
  final double speed;
  final double jumpForce;
  final int maxHp;
  final double attackRange;
  final int attackDamage;
  final Color themeColor;
  final String specialAbility;
  final String offhandName;
  final String offhandDescription;
  final double feetRatio;
  final String legsSpritePath;
  final double legX;
  final double legY;
  final double legBodyX;
  final double legBodyY;
  final double legPivotX;
  final double legPivotY;

  const PataponData({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.spritePath,
    required this.weaponSpritePath,
    required this.weaponRegion,
    required this.speed,
    required this.jumpForce,
    required this.maxHp,
    required this.attackRange,
    required this.attackDamage,
    required this.themeColor,
    required this.specialAbility,
    required this.offhandName,
    required this.offhandDescription,
    this.feetRatio = 0.15,
    this.legsSpritePath = '',
    this.legX = 0.5,
    this.legY = 0.94,
    this.legBodyX = 0,
    this.legBodyY = 0,
    this.legPivotX = 0,
    this.legPivotY = 0,
  });

  static const List<PataponData> allPatapons = [
    PataponData(
      id: 'drewniak',
      name: 'Drewniak',
      description: 'Tank z domkiem na głowie. Wolny ale wytrzymały.',
      imagePath: 'patapons_draw/Drewniak.jpeg',
      spritePath: 'patapons_draw/Drewniak.png',
      weaponSpritePath: 'patapons_draw/Drewniak - weapon.png',
      weaponRegion: WeaponRegion(left: 0.57, top: 0.25, width: 0.36, height: 0.32),
      speed: 140,
      jumpForce: 300,
      maxHp: 9,
      attackRange: 40,
      attackDamage: 2,
      themeColor: Color(0xFF8B4513),
      specialAbility: 'Wytrzymałość — przyjmuje o 50% mniej obrażeń',
      offhandName: 'Wstrząs',
      offhandDescription: 'Ogłusza wrogów w pobliżu (~300px) na 4 sek — stoją w miejscu.',
      feetRatio: 0.12,
      legsSpritePath: 'patapons_draw/Drewniak - Legs.png',
      legBodyX: 181,
      legBodyY: 300,
      legPivotX: 124,
      legPivotY: 12,
    ),
    PataponData(
      id: 'gaciar',
      name: 'Gaciar',
      description: 'Szybki świniak w klapkach. Ślizga się po platformach.',
      imagePath: 'patapons_draw/Gaciar.jpeg',
      spritePath: 'patapons_draw/Gaciar.png',
      weaponSpritePath: 'patapons_draw/Gaciar - weapon.png',
      weaponRegion: WeaponRegion(left: 0.50, top: 0.34, width: 0.34, height: 0.35),
      speed: 220,
      jumpForce: 420,
      maxHp: 5,
      attackRange: 30,
      attackDamage: 1,
      themeColor: Color(0xFFFF69B4),
      specialAbility: 'Ślizg — podwójny dash na ziemi',
      offhandName: 'Turbo Ślizg',
      offhandDescription: 'Turbo na 5 sek: 2× prędkość i +50% zasięgu ataku.',
      feetRatio: 0.14,
      legsSpritePath: 'patapons_draw/Gaciar - Legs.png',
      legBodyX: 145,
      legBodyY: 300,
      legPivotX: 141,
      legPivotY: 12,
    ),
    PataponData(
      id: 'grillak',
      name: 'Grillak',
      description: 'Mistrz grilla. Ciska kiełbachami jak pociskami.',
      imagePath: 'patapons_draw/Grillak.jpeg',
      spritePath: 'patapons_draw/Grillak.png',
      weaponSpritePath: 'patapons_draw/Grillak - weapon.png',
      weaponRegion: WeaponRegion(left: 0.55, top: 0.10, width: 0.42, height: 0.36),
      speed: 170,
      jumpForce: 350,
      maxHp: 5,
      attackRange: 200,
      attackDamage: 1,
      themeColor: Color(0xFF4169E1),
      specialAbility: 'Kiełbacho-strzelec — rzuca kiełbachy (5 szt. amunicji)',
      offhandName: 'Grad Kiełbasek',
      offhandDescription: 'Wystrzeliwuje naraz 8 kiełbasek na wszystkie strony (1 obrażenie każda).',
      feetRatio: 0.12,
      legsSpritePath: 'patapons_draw/Grillak - Legs.png',
      legBodyX: 143,
      legBodyY: 248,
      legPivotX: 110,
      legPivotY: 12,
    ),
    PataponData(
      id: 'kundziak',
      name: 'Kundziak',
      description: 'Techno-patapon z telefonem. Zamraża wrogów na chwilę.',
      imagePath: 'patapons_draw/Kundziak.jpeg',
      spritePath: 'patapons_draw/Kundziak.png',
      weaponSpritePath: 'patapons_draw/Kundziak - Copy.png',
      weaponRegion: WeaponRegion(left: 0.58, top: 0.25, width: 0.37, height: 0.33),
      speed: 160,
      jumpForce: 370,
      maxHp: 5,
      attackRange: 150,
      attackDamage: 1,
      themeColor: Color(0xFF4682B4),
      specialAbility: 'Hack — zamraża wrogów na 2 sekundy',
      offhandName: 'EMP',
      offhandDescription: 'Zamraża wrogów w dużym promieniu (~600px) na 3 sek.',
      feetRatio: 0.12,
      legsSpritePath: 'patapons_draw/Kundziak - Legs.png',
      legBodyX: 151,
      legBodyY: 229,
      legPivotX: 90,
      legPivotY: 12,
    ),
    PataponData(
      id: 'silny',
      name: 'Silny',
      description: 'Ognisty wojownik. Największy damage w grze.',
      imagePath: 'patapons_draw/Silny.jpeg',
      spritePath: 'patapons_draw/Silny.png',
      weaponSpritePath: 'patapons_draw/Silny - weapon.png',
      weaponRegion: WeaponRegion(left: 0.56, top: 0.04, width: 0.44, height: 0.52),
      speed: 160,
      jumpForce: 340,
      maxHp: 6,
      attackRange: 50,
      attackDamage: 3,
      themeColor: Color(0xFFFF4500),
      specialAbility: 'Ognisty miecz — podpala wrogów na 3 sekundy',
      offhandName: 'Fala Ognia',
      offhandDescription: 'Podpala wrogów wokół (~250px): 1 serce/sek przez 3 sek + spowolnienie o połowę na 4 sek.',
      feetRatio: 0.12,
      legsSpritePath: 'patapons_draw/Silny - Legs.png',
      legBodyX: 122,
      legBodyY: 265,
      legPivotX: 100,
      legPivotY: 12,
    ),
    PataponData(
      id: 'tutek',
      name: 'Tutek',
      description: 'Zbalansowany wojownik. Dobry na start.',
      imagePath: 'patapons_draw/Tutek.jpeg',
      spritePath: 'patapons_draw/Tutek.png',
      weaponSpritePath: 'patapons_draw/Tutek - weapon.png',
      weaponRegion: WeaponRegion(left: 0.60, top: 0.24, width: 0.35, height: 0.33),
      speed: 180,
      jumpForce: 370,
      maxHp: 6,
      attackRange: 45,
      attackDamage: 2,
      themeColor: Color(0xFFDAA520),
      specialAbility: 'Musztardowy atak — spowolnia trafionego wroga',
      offhandName: 'Chmura Musztardy',
      offhandDescription: 'Spowalnia wrogów o połowę w promieniu ~400px na 6 sek.',
      feetRatio: 0.12,
      legsSpritePath: 'patapons_draw/Tutek - Legs.png',
      legBodyX: 124,
      legBodyY: 186,
      legPivotX: 97,
      legPivotY: 12,
    ),
    PataponData(
      id: 'wlosatol',
      name: 'Włosatol',
      description: 'Fryzjerski support. Odpycha wrogów dmuchawą.',
      imagePath: 'patapons_draw/Włosatol.jpeg',
      spritePath: 'patapons_draw/Włosatol.png',
      weaponSpritePath: 'patapons_draw/Włosatol - weapon.png',
      weaponRegion: WeaponRegion(left: 0.51, top: 0.0, width: 0.46, height: 0.33),
      speed: 170,
      jumpForce: 360,
      maxHp: 5,
      attackRange: 100,
      attackDamage: 1,
      themeColor: Color(0xFFFF1493),
      specialAbility: 'Podmuch — odpycha wrogów suszarką',
      offhandName: 'Tornado',
      offhandDescription: 'Odrzuca wrogów (~300px) do tyłu, zadaje 1 obrażenie i spowalnia o połowę na 4 sek.',
      feetRatio: 0.16,
      legsSpritePath: 'patapons_draw/Włosatol - Legs.png',
      legBodyX: 123,
      legBodyY: 172,
      legPivotX: 91,
      legPivotY: 12,
    ),
    PataponData(
      id: 'zieloniak',
      name: 'Zieloniak',
      description: 'Obrońca z tarczą. Blokuje ataki frontalne.',
      imagePath: 'patapons_draw/Zieloniak.jpeg',
      spritePath: 'patapons_draw/Zieloniak.png',
      weaponSpritePath: 'patapons_draw/Zieloniak - weapon.png',
      weaponRegion: WeaponRegion(left: 0.54, top: 0.14, width: 0.44, height: 0.40),
      speed: 155,
      jumpForce: 320,
      maxHp: 8,
      attackRange: 45,
      attackDamage: 2,
      themeColor: Color(0xFF228B22),
      specialAbility: 'Tarcza — blokuje 1 atak co 5 sekund',
      offhandName: 'Tarcza Mocy',
      offhandDescription: 'Aktywuje tarczę — pełna nietykalność przez 5 sek.',
      feetRatio: 0.12,
      legsSpritePath: 'patapons_draw/Zieloniak - Legs.png',
      legBodyX: 140,
      legBodyY: 250,
      legPivotX: 102,
      legPivotY: 12,
    ),
  ];
}
