import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';

import 'retro_music.dart' show buildGameAudioContext;

class _SfxEv implements Comparable<_SfxEv> {
  final int sample;
  final int key;
  final bool on;
  final int velocity;
  _SfxEv(this.sample, this.key, this.on, [this.velocity = 100]);

  @override
  int compareTo(_SfxEv o) {
    final c = sample.compareTo(o.sample);
    if (c != 0) return c;
    if (!on && o.on) return -1;
    if (on && !o.on) return 1;
    return 0;
  }
}

class RetroSfx {
  RetroSfx._();
  static final RetroSfx instance = RetroSfx._();

  static const int _sr = 44100;
  static const int _bits = 16;
  static const int _ch = 1;

  final List<AudioPlayer> _pool = [];
  int _poolIndex = 0;
  static const int _poolSize = 6;
  final Random _rng = Random();

  late final Uint8List _jumpWav;
  late final Uint8List _coinWav;
  late final Uint8List _hitWav;
  late final Uint8List _stompWav;
  late final Uint8List _powerUpWav;
  late final Uint8List _deathWav;
  late final Uint8List _levelCompleteWav;
  late final Uint8List _offhandWav;
  late final Uint8List _upgradeWav;
  late final Uint8List _switchHeroWav;
  late final Uint8List _upgradeCheerWav;
  late final Uint8List _bossRoarWav;
  late final Uint8List _potionBadziewWav;
  late final Uint8List _potionSpokoWav;
  late final Uint8List _potionSuperWav;

  Future<void>? _initFuture;

  // Shared future, like RetroMusic.init(): a second call while the first is
  // still running must not re-assign the late final fields.
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    final sfData = await rootBundle.load('assets/soundfont/TimGM.sf2');
    final sfxSynth = Synthesizer.loadByteData(sfData, SynthesizerSettings(
      sampleRate: _sr,
      blockSize: 64,
      maximumPolyphony: 16,
      enableReverbAndChorus: true,
    ));

    _jumpWav = _genJump();
    _hitWav = _genHit();
    _stompWav = _genStomp();
    _offhandWav = _genOffhand();
    _switchHeroWav = _genSwitchHero();
    _deathWav = _genDeath();
    _upgradeCheerWav = _genUpgradeCheer();
    _bossRoarWav = _genBossRoar();

    _coinWav = _sfxRender(sfxSynth, 9, [
      [91, 0, 100, 127],
      [95, 100, 200, 127],
    ], gain: 2.5);
    _powerUpWav = _sfxRender(sfxSynth, 8, [
      [72, 0, 80, 90],
      [76, 80, 160, 90],
      [79, 160, 240, 90],
      [84, 240, 440, 100],
    ]);
    _levelCompleteWav = _sfxRender(sfxSynth, 56, [
      [72, 0, 130, 95],
      [76, 130, 260, 95],
      [79, 260, 390, 100],
      [84, 390, 800, 100],
    ], tailSec: 0.5);
    _upgradeWav = _sfxRender(sfxSynth, 10, [
      [76, 0, 65, 90],
      [79, 65, 130, 90],
      [84, 130, 195, 95],
      [88, 195, 400, 100],
    ]);
    // Potions: sad trombone "wah-wah-waaah" for the junk one, a pleasant
    // vibraphone chime for the decent one, a brass fanfare for the super one.
    _potionBadziewWav = _sfxRender(sfxSynth, 57, [
      [58, 0, 150, 85],
      [57, 150, 300, 85],
      [56, 300, 450, 85],
      [55, 450, 900, 90],
    ], tailSec: 0.25);
    _potionSpokoWav = _sfxRender(sfxSynth, 11, [
      [76, 0, 140, 100],
      [81, 120, 520, 105],
    ], tailSec: 0.4, gain: 1.6);
    _potionSuperWav = _sfxRender(sfxSynth, 61, [
      [72, 0, 100, 100],
      [76, 100, 200, 100],
      [79, 200, 300, 105],
      [84, 300, 800, 115],
      [88, 300, 800, 105],
    ], tailSec: 0.4);

    final ctx = buildGameAudioContext();
    for (int i = 0; i < _poolSize; i++) {
      final p = AudioPlayer();
      await p.setAudioContext(ctx);
      _pool.add(p);
    }
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
  }

  Future<void> jump() => _play(_jumpWav);
  Future<void> coin() => _play(_coinWav);
  Future<void> hit() => _play(_hitWav);
  Future<void> stomp() => _play(_stompWav);
  Future<void> powerUp() => _play(_powerUpWav);
  Future<void> death() => _play(_deathWav);
  Future<void> levelComplete() => _play(_levelCompleteWav);
  Future<void> offhand() => _play(_offhandWav);
  Future<void> upgrade() => _play(_upgradeWav);
  Future<void> switchHero() => _play(_switchHeroWav);
  Future<void> upgradeCheer() => _play(_upgradeCheerWav);
  Future<void> bossRoar() => _play(_bossRoarWav);
  Future<void> potionBadziew() => _play(_potionBadziewWav);
  Future<void> potionSpoko() => _play(_potionSpokoWav);
  Future<void> potionSuper() => _play(_potionSuperWav);

  Future<void> _play(Uint8List wavBytes) async {
    final player = _pool[_poolIndex % _poolSize];
    _poolIndex++;
    await player.stop();
    await player.play(BytesSource(wavBytes));
  }

  // -- SoundFont SFX renderer (notes: [midiKey, startMs, endMs, velocity]) --

  Uint8List _sfxRender(Synthesizer synth, int preset, List<List<int>> notes, {double tailSec = 0.3, double gain = 1.0}) {
    synth.reset();
    synth.processMidiMessage(channel: 0, command: 0xC0, data1: preset, data2: 0);

    int maxEndMs = 0;
    for (final n in notes) {
      if (n[2] > maxEndMs) maxEndMs = n[2];
    }

    final totalSamples = ((maxEndMs / 1000.0 + tailSec) * _sr).round();
    final left = Float32List(totalSamples);
    final right = Float32List(totalSamples);

    final events = <_SfxEv>[];
    for (final n in notes) {
      events.add(_SfxEv((n[1] / 1000.0 * _sr).round(), n[0], true, n[3]));
      events.add(_SfxEv((n[2] / 1000.0 * _sr).round(), n[0], false));
    }
    events.sort();

    int evIdx = 0;
    const blk = 256;
    for (int p = 0; p < totalSamples; p += blk) {
      while (evIdx < events.length && events[evIdx].sample < p + blk) {
        final e = events[evIdx++];
        if (e.on) {
          synth.noteOn(channel: 0, key: e.key, velocity: e.velocity);
        } else {
          synth.noteOff(channel: 0, key: e.key);
        }
      }
      final cnt = min(blk, totalSamples - p);
      final lb = Float32List(cnt);
      final rb = Float32List(cnt);
      synth.render(lb, rb);
      left.setRange(p, p + cnt, lb);
      right.setRange(p, p + cnt, rb);
    }

    final mono = Int16List(totalSamples);
    for (int i = 0; i < totalSamples; i++) {
      mono[i] = (((left[i] + right[i]) * 0.5 * gain).clamp(-1.0, 1.0) * 32000).round();
    }
    return _makeWav(mono);
  }

  // -- WAV packaging (16-bit signed LE) --

  Uint8List _makeWav(Int16List samples) {
    final int dataSize = samples.length * 2;
    final int fileSize = 36 + dataSize;
    final ByteData hdr = ByteData(44);

    hdr.setUint8(0, 0x52); hdr.setUint8(1, 0x49); hdr.setUint8(2, 0x46); hdr.setUint8(3, 0x46);
    hdr.setUint32(4, fileSize, Endian.little);
    hdr.setUint8(8, 0x57); hdr.setUint8(9, 0x41); hdr.setUint8(10, 0x56); hdr.setUint8(11, 0x45);

    hdr.setUint8(12, 0x66); hdr.setUint8(13, 0x6D); hdr.setUint8(14, 0x74); hdr.setUint8(15, 0x20);
    hdr.setUint32(16, 16, Endian.little);
    hdr.setUint16(20, 1, Endian.little);
    hdr.setUint16(22, _ch, Endian.little);
    hdr.setUint32(24, _sr, Endian.little);
    hdr.setUint32(28, _sr * _ch * _bits ~/ 8, Endian.little);
    hdr.setUint16(32, _ch * _bits ~/ 8, Endian.little);
    hdr.setUint16(34, _bits, Endian.little);

    hdr.setUint8(36, 0x64); hdr.setUint8(37, 0x61); hdr.setUint8(38, 0x74); hdr.setUint8(39, 0x61);
    hdr.setUint32(40, dataSize, Endian.little);

    final Uint8List wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, hdr.buffer.asUint8List());
    final pcmBytes = samples.buffer.asUint8List(samples.offsetInBytes, dataSize);
    wav.setRange(44, 44 + dataSize, pcmBytes);
    return wav;
  }

  // -- Waveforms (-1.0 to 1.0) --

  double _sin(double phase) => sin(2.0 * pi * phase);
  double _tri(double phase) {
    final p = phase % 1.0;
    return p < 0.5 ? (4.0 * p - 1.0) : (3.0 - 4.0 * p);
  }
  double _sq(double phase) => (phase % 1.0) < 0.5 ? 1.0 : -1.0;
  double _noise() => _rng.nextDouble() * 2.0 - 1.0;

  int _s16(double v) => (v.clamp(-1.0, 1.0) * 32000).round();

  double _expDecay(double t, double decay) => exp(-t * decay);

  Uint8List _genJump() {
    const dur = 0.18;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final freq = 350.0 + 900.0 * t * t;
      ph1 += freq / _sr;
      ph2 += (freq * 2.01) / _sr;

      final env = _expDecay(t, 1.5) * (1.0 - t * 0.3);
      final s = _sin(ph1) * 0.6 + _tri(ph2) * 0.3 + _sin(ph1 * 3) * 0.1;
      out[i] = _s16(s * env * 0.7);
    }
    return _makeWav(out);
  }

  Uint8List _genHit() {
    const dur = 0.15;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final impactEnv = _expDecay(t, 12.0);
      final bassEnv = _expDecay(t, 6.0);

      final noiseAmt = _noise() * impactEnv * 0.5;

      final bassFreq = 120.0 - 60.0 * t;
      ph1 += bassFreq / _sr;
      final bass = _sin(ph1) * bassEnv * 0.6;

      final crunchFreq = 300.0 + _sin(ph2 * 7) * 200.0 * impactEnv;
      ph2 += crunchFreq / _sr;
      final crunch = _sq(ph2) * impactEnv * 0.25;

      out[i] = _s16((bass + crunch + noiseAmt) * 0.8);
    }
    return _makeWav(out);
  }

  Uint8List _genStomp() {
    const dur = 0.14;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final env = _expDecay(t, 8.0);

      final freq = 800.0 - 650.0 * t;
      ph1 += freq / _sr;
      ph2 += (freq * 0.5) / _sr;

      final s = _sin(ph1) * 0.5 + _tri(ph2) * 0.3 + _noise() * env * 0.15;
      out[i] = _s16(s * env * 0.75);
    }
    return _makeWav(out);
  }

  Uint8List _genDeath() {
    const dur = 0.7;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0, ph3 = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final baseFreq = 600.0 - 400.0 * t;
      final vibrato = sin(2.0 * pi * 6.0 * t) * 40.0 * t;
      final freq = baseFreq + vibrato;
      ph1 += freq / _sr;
      ph2 += (freq * 0.75) / _sr;
      ph3 += (freq * 1.5) / _sr;

      final env = _expDecay(t, 2.5);
      final wobble = 0.7 + 0.3 * sin(2.0 * pi * 12.0 * t);

      final s = _tri(ph1) * 0.4 + _sin(ph2) * 0.35 + _sin(ph3) * 0.15 + _noise() * t * 0.1;
      out[i] = _s16(s * env * wobble * 0.6);
    }
    return _makeWav(out);
  }

  Uint8List _genOffhand() {
    const dur = 0.22;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final freq = 200.0 + 1500.0 * t * t;
      final modFreq = freq * 3.0;
      ph2 += modFreq / _sr;
      final fmMod = sin(2.0 * pi * ph2) * 300.0 * (1.0 - t);
      ph1 += (freq + fmMod) / _sr;

      final env = (1.0 - t * 0.5) * _expDecay(t * 0.3, 1.0);
      final crackle = _noise() * _expDecay(t, 6.0) * 0.3;
      final s = _sin(ph1) * 0.5 + _tri(ph1 * 2) * 0.2 + crackle;
      out[i] = _s16(s * env * 0.75);
    }
    return _makeWav(out);
  }

  Uint8List _genSwitchHero() {
    const dur = 0.35;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0, ph3 = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final whooshFreq = 200.0 + 1200.0 * (1.0 - t);
      ph1 += whooshFreq / _sr;
      final whoosh = _noise() * _expDecay(t, 4.0) * 0.3 + _sin(ph1) * _expDecay(t, 5.0) * 0.2;

      final sparkleT = (t - 0.4).clamp(0.0, 1.0);
      ph2 += 1200.0 / _sr;
      ph3 += 1800.0 / _sr;
      final sparkleEnv = sparkleT > 0 ? _expDecay(sparkleT * 2, 3.0) * 0.4 : 0.0;
      final sparkle = (_tri(ph2) * 0.5 + _sin(ph3) * 0.3) * sparkleEnv;

      out[i] = _s16((whoosh + sparkle) * 0.7);
    }
    return _makeWav(out);
  }

  Uint8List _genUpgradeCheer() {
    const dur = 0.6;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0, ph3 = 0, ph4 = 0;

    const f1 = 523.25, f2 = 659.25, f3 = 783.99;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      ph1 += f1 / _sr;
      ph2 += f2 / _sr;
      ph3 += f3 / _sr;
      ph4 += (f3 * 2) / _sr;

      final attack = t < 0.05 ? t / 0.05 : 1.0;
      final env = attack * _expDecay((t - 0.05).clamp(0.0, 1.0), 2.5);

      final chord = _tri(ph1) * 0.25 + _sin(ph2) * 0.25 + _tri(ph3) * 0.2 + _sin(ph4) * 0.1;

      final crowdEnv = _expDecay(t * 0.8, 1.5) * 0.15;
      final crowd = _noise() * crowdEnv * (0.7 + 0.3 * _sin(ph1 * 6));

      final sparkleT = (t - 0.3).clamp(0.0, 1.0);
      final sparkle = sparkleT > 0 ? _sin(ph4 * 1.5) * _expDecay(sparkleT, 4.0) * 0.15 : 0.0;

      out[i] = _s16((chord * env + crowd + sparkle) * 0.7);
    }
    return _makeWav(out);
  }

  Uint8List _genBossRoar() {
    const dur = 0.8;
    final n = (_sr * dur).toInt();
    final out = Int16List(n);
    double ph1 = 0, ph2 = 0, ph3 = 0;

    for (int i = 0; i < n; i++) {
      final t = i / n;
      final baseFreq = 80.0 + 30.0 * sin(2.0 * pi * 5.0 * t);
      ph1 += baseFreq / _sr;
      ph2 += (baseFreq * 1.5) / _sr;
      ph3 += (baseFreq * 3.0) / _sr;

      final attack = t < 0.08 ? t / 0.08 : 1.0;
      final env = attack * _expDecay((t - 0.08).clamp(0.0, 1.0), 2.0);
      final rumble = _sq(ph1) * 0.35 + _tri(ph2) * 0.25 + _sin(ph3) * 0.15;
      final noiseLayer = _noise() * env * 0.25 * (0.6 + 0.4 * _sin(ph1 * 8));
      out[i] = _s16((rumble * env + noiseLayer) * 0.8);
    }
    return _makeWav(out);
  }
}
