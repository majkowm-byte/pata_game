import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:audioplayers/audioplayers.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';

AudioContext buildGameAudioContext() => AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
      // `ambient` already mixes with other audio; passing `mixWithOthers`
      // with it trips an assert in AudioContextIOS (debug builds didn't start).
      iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
    );

class _Ev implements Comparable<_Ev> {
  final int sample;
  final int channel;
  final int key;
  final bool on;
  final int velocity;
  _Ev(this.sample, this.channel, this.key, this.on, [this.velocity = 100]);

  @override
  int compareTo(_Ev o) {
    final c = sample.compareTo(o.sample);
    if (c != 0) return c;
    if (!on && o.on) return -1;
    if (on && !o.on) return 1;
    return 0;
  }
}

class RetroMusic {
  RetroMusic._();
  static final RetroMusic instance = RetroMusic._();
  static const int _sr = 44100;
  // One rendered track is several MB of WAV, so only the most recently used
  // ones are kept (menu, current level, upcoming boss + one spare).
  static const int _maxCachedTracks = 4;

  AudioPlayer? _player;
  ByteData? _soundFont;
  Future<void>? _initFuture;

  int _currentKey = -1;
  final Map<int, Uint8List> _cache = {}; // insertion order = LRU order
  final Map<int, Future<Uint8List>> _rendering = {};

  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    await AudioPlayer.global.setAudioContext(buildGameAudioContext());

    _soundFont = await rootBundle.load('assets/soundfont/TimGM.sf2');

    final p = AudioPlayer();
    await p.setAudioContext(buildGameAudioContext());
    await p.setReleaseMode(ReleaseMode.loop);
    await p.setVolume(0.72);
    _player = p;
  }

  Future<void> playMenu() => _switchTo(0);

  Future<void> playLevel(int lv) async {
    await _switchTo(lv.clamp(1, 10));
    // Render the next boss theme in the background while the level is being
    // played, so the boss intro doesn't have to wait for it.
    _track(_nextBossKey).ignore();
  }

  static final _bossRng = Random();
  int _nextBossKey = 99 + _bossRng.nextInt(16);

  Future<void> playBoss() {
    final key = _nextBossKey;
    _nextBossKey = 99 + _bossRng.nextInt(16);
    return _switchTo(key);
  }

  Future<void> _switchTo(int key) async {
    await init();
    if (key == _currentKey) return;
    _currentKey = key;
    final Uint8List wav;
    try {
      wav = await _track(key);
    } catch (_) {
      if (key == _currentKey) _currentKey = -1;
      return;
    }
    // Another track may have been requested while this one was rendering.
    if (key != _currentKey) return;
    try { await _player!.stop(); } catch (_) {}
    if (key != _currentKey) return;
    try { await _player!.play(BytesSource(wav)); } catch (_) {}
  }

  /// WAV bytes for [key], rendered on a background isolate when not cached.
  /// Rendering a full SoundFont track takes seconds of CPU; doing it on the
  /// UI isolate froze the game on every new level or boss track.
  Future<Uint8List> _track(int key) {
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // re-insert as most recently used
      return Future.value(cached);
    }
    return _rendering[key] ??= _render(key, _soundFont!).then((wav) {
      _cache[key] = wav;
      while (_cache.length > _maxCachedTracks) {
        _cache.remove(_cache.keys.first);
      }
      return wav;
    }).whenComplete(() {
      // Block body on purpose: returning the removed future (=> form) would
      // make whenComplete wait for itself and never complete.
      _rendering.remove(key);
    });
  }

  // Static so the isolate closure captures only its arguments, not `this`.
  static Future<Uint8List> _render(int key, ByteData soundFont) =>
      Isolate.run(() => _TrackGenerator(soundFont)._generate(key));

  Future<void> stop() async {
    _currentKey = -1;
    try { await _player?.stop(); } catch (_) {}
  }

  void dispose() {
    try { _player?.dispose(); } catch (_) {}
    _player = null;
  }
}

/// Renders the music themes. Runs on a background isolate (see
/// [RetroMusic._render]), so it must not touch Flutter or player state.
class _TrackGenerator {
  _TrackGenerator(ByteData soundFont)
      : _synth = Synthesizer.loadByteData(soundFont, SynthesizerSettings(
          sampleRate: _sr,
          blockSize: 64,
          maximumPolyphony: 64,
          enableReverbAndChorus: true,
        ));

  static const int _sr = RetroMusic._sr;

  final Synthesizer _synth;

  static const Map<int, List<int>> _chords = {
    0: [0, 4, 7],
    1: [0, 3, 7],
    2: [0, 4, 7, 11],
    3: [0, 3, 7, 10],
    4: [0, 4, 7, 10],
    5: [0, 5, 7],
    6: [0, 3, 7, 10, 14],
    7: [0, 4, 7, 11, 14],
    8: [0, 3, 6, 10],
  };

  Uint8List _generate(int key) {
    switch (key) {
      case 0:  return _mkMenu();
      case 1:  return _mkMeadow();
      case 2:  return _mkForest();
      case 3:  return _mkJungle();
      case 4:  return _mkDesert();
      case 5:  return _mkSpace();
      case 6:  return _mkLava();
      case 7:  return _mkMeadow(transpose: 5, bpm: 128);
      case 8:  return _mkForest(transpose: -3, bpm: 118);
      case 9:  return _mkDesert(transpose: 3, bpm: 104);
      case 10: return _mkLava(transpose: 2, bpm: 150);
      case 99:  return _mkBoss();
      case 100: return _mkBoss2();
      case 101: return _mkBoss3();
      case 102: return _mkBoss4();
      case 103: return _mkBoss5();
      case 104: return _mkBoss6();
      case 105: return _mkBoss7();
      case 106: return _mkBoss8();
      case 107: return _mkBoss9();
      case 108: return _mkBoss10();
      case 109: return _mkBoss11();
      case 110: return _mkBoss12();
      case 111: return _mkBoss13();
      case 112: return _mkBoss14();
      case 113: return _mkBoss15();
      case 114: return _mkBoss16();
      default: return _mkLava(transpose: 2, bpm: 150);
    }
  }

  // ===================== Stereo WAV encoder =====================
  Uint8List _stereoWav(Float32List left, Float32List right) {
    final n = left.length;
    final dataSize = n * 4;
    final h = ByteData(44);
    h.setUint8(0, 0x52); h.setUint8(1, 0x49); h.setUint8(2, 0x46); h.setUint8(3, 0x46);
    h.setUint32(4, 36 + dataSize, Endian.little);
    h.setUint8(8, 0x57); h.setUint8(9, 0x41); h.setUint8(10, 0x56); h.setUint8(11, 0x45);
    h.setUint8(12, 0x66); h.setUint8(13, 0x6D); h.setUint8(14, 0x74); h.setUint8(15, 0x20);
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little);
    h.setUint16(22, 2, Endian.little);
    h.setUint32(24, _sr, Endian.little);
    h.setUint32(28, _sr * 4, Endian.little);
    h.setUint16(32, 4, Endian.little);
    h.setUint16(34, 16, Endian.little);
    h.setUint8(36, 0x64); h.setUint8(37, 0x61); h.setUint8(38, 0x74); h.setUint8(39, 0x61);
    h.setUint32(40, dataSize, Endian.little);

    final wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, h.buffer.asUint8List());
    final bd = ByteData.view(wav.buffer, 44);
    for (int i = 0; i < n; i++) {
      bd.setInt16(i * 4, (left[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
      bd.setInt16(i * 4 + 2, (right[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
    }
    return wav;
  }

  // ===================== Helpers =====================
  List<int> _rep(List<int> bar, int n) {
    final r = <int>[];
    for (int i = 0; i < n; i++) r.addAll(bar);
    return r;
  }

  List<int> _tp(List<int> notes, int semis) {
    if (semis == 0) return notes;
    final r = List<int>.from(notes);
    for (int i = 0; i < r.length; i += 2) {
      if (r[i] > 0) r[i] += semis;
    }
    return r;
  }

  List<int> _tpad(List<int> ch, int semis) {
    if (semis == 0) return ch;
    final r = List<int>.from(ch);
    for (int i = 0; i < r.length; i += 3) {
      r[i] += semis;
    }
    return r;
  }

  // ===================== SoundFont renderer =====================
  // Drum flags: 1=kick, 2=snare, 4=closed hat, 8=open hat, 16=crash
  Uint8List _renderSf({
    required double bpm,
    required List<int> padSeq,
    required List<int> bassSeq,
    required List<int> leadSeq,
    required List<int> drumPat,
    List<int> counterSeq = const [],
    int padPreset = 48,
    int leadPreset = 73,
    int bassPreset = 32,
    int counterPreset = 46,
    int padVel = 65,
    int leadVel = 95,
    int bassVel = 80,
    int counterVel = 55,
    int kickVel = 85,
    int snareVel = 75,
    int hatVel = 55,
  }) {
    final synth = _synth;
    synth.reset();

    synth.processMidiMessage(channel: 0, command: 0xC0, data1: padPreset, data2: 0);
    synth.processMidiMessage(channel: 1, command: 0xC0, data1: leadPreset, data2: 0);
    synth.processMidiMessage(channel: 2, command: 0xC0, data1: bassPreset, data2: 0);
    if (counterSeq.isNotEmpty) {
      synth.processMidiMessage(channel: 3, command: 0xC0, data1: counterPreset, data2: 0);
    }

    final stepSamples = (60.0 / bpm / 4.0 * _sr).round();
    final events = <_Ev>[];

    // Pad chord events (channel 0)
    int pos = 0;
    for (int i = 0; i < padSeq.length; i += 3) {
      final root = padSeq[i];
      final type = padSeq[i + 1];
      final steps = padSeq[i + 2];
      final ivs = _chords[type] ?? _chords[0]!;
      for (final iv in ivs) {
        events.add(_Ev(pos * stepSamples, 0, root + iv, true, padVel));
        events.add(_Ev((pos + steps) * stepSamples - 1, 0, root + iv, false));
      }
      pos += steps;
    }

    // Lead melody with velocity accents (channel 1)
    pos = 0;
    for (int i = 0; i < leadSeq.length; i += 2) {
      final midi = leadSeq[i];
      final steps = leadSeq[i + 1];
      if (midi > 0) {
        int vel = leadVel;
        if (pos % 16 == 0) vel = min(127, vel + 12);
        else if (pos % 8 == 0) vel = min(127, vel + 6);
        if (steps <= 1) vel = max(40, vel - 15);
        if (steps >= 8) vel = min(127, vel + 5);
        events.add(_Ev(pos * stepSamples, 1, midi, true, vel));
        events.add(_Ev((pos + steps) * stepSamples - 1, 1, midi, false));
      }
      pos += steps;
    }

    // Counter melody with softer accents (channel 3)
    if (counterSeq.isNotEmpty) {
      pos = 0;
      for (int i = 0; i < counterSeq.length; i += 2) {
        final midi = counterSeq[i];
        final steps = counterSeq[i + 1];
        if (midi > 0) {
          int vel = counterVel;
          if (pos % 16 == 0) vel = min(127, vel + 8);
          events.add(_Ev(pos * stepSamples, 3, midi, true, vel));
          events.add(_Ev((pos + steps) * stepSamples - 1, 3, midi, false));
        }
        pos += steps;
      }
    }

    // Bass with mild accents (channel 2)
    pos = 0;
    for (int i = 0; i < bassSeq.length; i += 2) {
      final midi = bassSeq[i];
      final steps = bassSeq[i + 1];
      if (midi > 0) {
        int vel = bassVel;
        if (pos % 16 == 0) vel = min(127, vel + 8);
        events.add(_Ev(pos * stepSamples, 2, midi, true, vel));
        events.add(_Ev((pos + steps) * stepSamples - 1, 2, midi, false));
      }
      pos += steps;
    }

    // Drums (channel 9 = GM percussion)
    for (int i = 0; i < drumPat.length; i++) {
      final fl = drumPat[i];
      final sp = i * stepSamples;
      if (fl & 1 != 0) {
        events.add(_Ev(sp, 9, 36, true, kickVel));
        events.add(_Ev(sp + stepSamples ~/ 2, 9, 36, false));
      }
      if (fl & 2 != 0) {
        events.add(_Ev(sp, 9, 38, true, snareVel));
        events.add(_Ev(sp + stepSamples ~/ 2, 9, 38, false));
      }
      if (fl & 4 != 0) {
        events.add(_Ev(sp, 9, 42, true, hatVel));
        events.add(_Ev(sp + stepSamples ~/ 4, 9, 42, false));
      }
      if (fl & 8 != 0) {
        events.add(_Ev(sp, 9, 46, true, hatVel + 5));
        events.add(_Ev(sp + stepSamples ~/ 2, 9, 46, false));
      }
      if (fl & 16 != 0) {
        events.add(_Ev(sp, 9, 49, true, min(127, kickVel + 10)));
        events.add(_Ev(sp + stepSamples, 9, 49, false));
      }
    }

    events.sort();

    // Calculate total duration
    int maxSteps = drumPat.length;
    { int s = 0; for (int i = 2; i < padSeq.length; i += 3) s += padSeq[i]; if (s > maxSteps) maxSteps = s; }
    { int s = 0; for (int i = 1; i < leadSeq.length; i += 2) s += leadSeq[i]; if (s > maxSteps) maxSteps = s; }
    { int s = 0; for (int i = 1; i < bassSeq.length; i += 2) s += bassSeq[i]; if (s > maxSteps) maxSteps = s; }
    if (counterSeq.isNotEmpty) {
      int s = 0; for (int i = 1; i < counterSeq.length; i += 2) s += counterSeq[i]; if (s > maxSteps) maxSteps = s;
    }
    final totalSamples = maxSteps * stepSamples + _sr;

    // Render in 256-sample blocks
    final left = Float32List(totalSamples);
    final right = Float32List(totalSamples);
    int evIdx = 0;
    const blk = 256;

    for (int p = 0; p < totalSamples; p += blk) {
      while (evIdx < events.length && events[evIdx].sample < p + blk) {
        final e = events[evIdx++];
        if (e.on) {
          synth.noteOn(channel: e.channel, key: e.key, velocity: e.velocity);
        } else {
          synth.noteOff(channel: e.channel, key: e.key);
        }
      }
      final cnt = min(blk, totalSamples - p);
      final lb = Float32List(cnt);
      final rb = Float32List(cnt);
      synth.render(lb, rb);
      left.setRange(p, p + cnt, lb);
      right.setRange(p, p + cnt, rb);
    }

    return _stereoWav(left, right);
  }

  // ===================== THEMES =====================
  // Each theme: A section (original) + B section (contrasting development)
  // Counter melody adds arpeggio texture on a separate instrument.
  // Drum fills mark section boundaries.

  // MENU — hopeful, gentle. Am - F - C - G. 92 BPM.
  Uint8List _mkMenu({int transpose = 0, double bpm = 92}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([57,1,16, 53,0,16, 60,0,16, 55,4,16], 4), transpose),
      bassSeq: _tp(_rep([
        45,4, 52,4, 45,4, 52,4, 41,4, 48,4, 41,4, 48,4,
        48,4, 55,4, 48,4, 55,4, 43,4, 50,4, 43,4, 50,4,
      ], 4), transpose),
      leadSeq: _tp([
        // A: gentle ascending phrases
        64,4, 69,4, 72,4, 71,4,  69,4, 67,4, 65,8,
        76,4, 74,4, 72,4, 67,4,  74,4, 71,4, 67,8,
        64,4, 69,4, 72,4, 76,4,  74,4, 72,4, 71,8,
        72,4, 71,4, 69,4, 67,4,  69,16,
        // B: higher, more lyrical
        76,3, 77,1, 79,4, 81,4, 79,4,  77,4, 76,4, 74,4, 72,4,
        84,4, 83,2, 84,2, 81,4, 79,4,  79,4, 77,4, 76,8,
        74,4, 76,4, 79,4, 76,4,  77,6, 74,2, 72,8,
        72,4, 74,4, 76,4, 79,4,  76,4, 74,4, 72,4, 69,4,
      ], transpose),
      counterSeq: _tp(_rep([
        57,2, 60,2, 64,2, 60,2, 57,2, 60,2, 64,2, 60,2,
        53,2, 57,2, 60,2, 57,2, 53,2, 57,2, 60,2, 57,2,
        48,2, 52,2, 55,2, 52,2, 48,2, 52,2, 55,2, 52,2,
        43,2, 47,2, 50,2, 47,2, 43,2, 47,2, 50,2, 47,2,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,0,0,4, 0,0,2,0, 1,0,0,4, 0,0,2,0], 7),
        1,0,4,2, 2,0,4,2, 1,2,2,2, 17,0,8,0,
        ..._rep([1,0,0,4, 0,0,2,0, 1,0,4,0, 0,0,2,4], 7),
        1,0,4,2, 2,4,2,4, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 48, leadPreset: 73, bassPreset: 32, counterPreset: 46,
      padVel: 60, leadVel: 88, bassVel: 75, counterVel: 48,
    );
  }

  // MEADOW (lvl1) — bright adventure. C - G - Am - F. 120 BPM.
  Uint8List _mkMeadow({int transpose = 0, double bpm = 120}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([60,7,16, 55,0,16, 57,3,16, 53,2,16], 4), transpose),
      bassSeq: _tp(_rep([
        48,2, 48,2, 55,2, 52,2, 43,2, 43,2, 50,2, 47,2,
        45,2, 45,2, 52,2, 48,2, 41,2, 41,2, 48,2, 45,2,
      ], 8), transpose),
      leadSeq: _tp([
        // A: bright, adventurous
        72,4, 76,4, 79,4, 76,4,  74,4, 79,4, 71,4, 74,4,
        72,4, 74,4, 76,8,  69,4, 72,4, 76,4, 72,4,
        76,4, 79,4, 84,4, 79,4,  77,4, 74,4, 72,8,
        71,4, 72,4, 74,4, 76,4,  72,16,
        // B: playful, running passages
        79,2, 76,2, 79,4, 84,4, 79,4,  83,4, 79,4, 76,4, 74,4,
        76,2, 74,2, 72,4, 69,4, 72,4,  77,4, 76,2, 74,2, 72,8,
        84,4, 81,4, 79,4, 76,4,  79,2, 81,2, 84,4, 81,4, 79,4,
        76,4, 74,4, 72,4, 69,4,  72,2, 74,2, 76,4, 74,4, 72,4,
      ], transpose),
      counterSeq: _tp(_rep([
        60,2, 64,2, 67,2, 64,2, 60,2, 64,2, 67,2, 64,2,
        55,2, 59,2, 62,2, 59,2, 55,2, 59,2, 62,2, 59,2,
        57,2, 60,2, 64,2, 60,2, 57,2, 60,2, 64,2, 60,2,
        53,2, 57,2, 60,2, 57,2, 53,2, 57,2, 60,2, 57,2,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,0,4,0, 2,0,4,0, 1,0,4,4, 2,0,4,0], 7),
        1,0,4,2, 1,0,4,2, 2,4,2,4, 17,0,8,0,
        ..._rep([1,0,4,0, 2,0,4,4, 1,0,4,0, 2,0,4,0], 7),
        1,4,2,4, 1,4,2,4, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 48, leadPreset: 68, bassPreset: 33,
      counterPreset: 45,
      padVel: 60, leadVel: 90, bassVel: 82, counterVel: 50,
    );
  }

  // FOREST (lvl2) — mysterious, wistful. Em - C - G - D. 108 BPM.
  Uint8List _mkForest({int transpose = 0, double bpm = 108}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([52,3,16, 48,2,16, 55,2,16, 50,0,16], 4), transpose),
      bassSeq: _tp(_rep([
        40,4, 47,4, 40,4, 47,4, 36,4, 43,4, 36,4, 43,4,
        43,4, 50,4, 43,4, 50,4, 38,4, 45,4, 38,4, 45,4,
      ], 4), transpose),
      leadSeq: _tp([
        // A: wistful, flowing
        64,6, 67,2, 71,4, 72,4,  71,4, 67,4, 64,8,
        72,4, 71,4, 67,4, 64,4,  62,4, 67,4, 64,8,
        67,4, 71,4, 74,4, 71,4,  72,4, 74,4, 76,8,
        74,4, 71,4, 67,4, 62,4,  64,16,
        // B: brighter but still mysterious
        71,4, 72,2, 74,2, 76,4, 74,4,  72,6, 67,2, 64,8,
        67,4, 71,4, 74,2, 76,2, 74,4,  72,4, 71,4, 67,8,
        76,4, 74,4, 72,2, 71,2, 72,4,  74,4, 72,4, 67,4, 64,4,
        67,2, 71,2, 74,4, 72,4, 71,4,  72,4, 71,2, 67,2, 64,8,
      ], transpose),
      counterSeq: _tp(_rep([
        52,2, 55,2, 59,2, 55,2, 52,2, 55,2, 59,2, 55,2,
        48,2, 52,2, 55,2, 52,2, 48,2, 52,2, 55,2, 52,2,
        43,2, 47,2, 50,2, 47,2, 43,2, 47,2, 50,2, 47,2,
        50,2, 54,2, 57,2, 54,2, 50,2, 54,2, 57,2, 54,2,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,0,0,4, 0,0,2,0, 1,0,0,0, 0,0,2,4], 7),
        1,0,0,2, 0,2,0,2, 2,0,2,0, 17,0,0,0,
        ..._rep([1,0,0,4, 0,0,2,0, 1,0,4,0, 0,0,2,4], 7),
        1,0,4,2, 0,2,2,0, 1,2,0,2, 17,0,8,0,
      ],
      padPreset: 89, leadPreset: 75, bassPreset: 32,
      counterPreset: 8,
      padVel: 55, leadVel: 85, bassVel: 72, counterVel: 45,
    );
  }

  // JUNGLE (lvl3) — driving, tribal. Am - Dm7 - E7 - Am. 132 BPM.
  Uint8List _mkJungle({int transpose = 0, double bpm = 132}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([57,1,16, 50,3,16, 52,4,16, 57,1,16], 4), transpose),
      bassSeq: _tp(_rep([
        45,2, 45,1, 45,1, 52,2, 45,2, 50,2, 50,1, 50,1, 57,2, 50,2,
        52,2, 52,1, 52,1, 59,2, 52,2, 45,2, 45,2, 52,2, 45,2,
      ], 8), transpose),
      leadSeq: _tp([
        // A: driving, rhythmic
        69,2, 72,2, 76,4, 74,2, 72,2, 69,4,
        74,2, 77,2, 81,4, 77,2, 74,2, 72,4,
        76,2, 80,2, 83,4, 80,2, 76,2, 72,4,
        69,4, 76,4, 72,4, 69,4,
        // A repeat
        69,2, 72,2, 76,4, 74,2, 72,2, 69,4,
        74,2, 77,2, 81,4, 77,2, 74,2, 72,4,
        76,2, 80,2, 83,4, 80,2, 76,2, 72,4,
        69,4, 76,4, 72,4, 69,4,
        // B: more syncopated, aggressive
        72,1, 74,1, 76,2, 79,4, 76,4, 74,4,
        77,2, 74,2, 72,4, 69,4, 72,4,
        76,4, 80,2, 76,2, 72,4, 69,4,
        69,2, 72,2, 76,2, 79,2, 76,2, 72,2, 69,4,
        74,2, 77,2, 81,4, 77,4, 74,4,
        80,2, 76,2, 72,4, 76,4, 72,4,
        69,2, 72,2, 76,4, 72,4, 69,4,
        69,4, 76,4, 72,4, 69,4,
      ], transpose),
      counterSeq: _tp(_rep([
        57,2, 60,2, 64,2, 60,2, 57,2, 60,2, 64,2, 60,2,
        50,2, 53,2, 57,2, 53,2, 50,2, 53,2, 57,2, 53,2,
        52,2, 56,2, 59,2, 56,2, 52,2, 56,2, 59,2, 56,2,
        57,2, 60,2, 64,2, 60,2, 57,2, 60,2, 64,2, 60,2,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,0,4,2, 1,0,4,0, 1,4,4,2, 1,0,4,4], 7),
        1,4,2,4, 1,2,1,2, 2,4,2,4, 17,0,8,0,
        ..._rep([1,0,4,2, 1,4,4,0, 1,0,4,2, 1,0,4,4], 7),
        1,2,1,2, 2,4,1,4, 2,4,2,4, 17,0,0,0,
      ],
      padPreset: 50, leadPreset: 81, bassPreset: 36,
      counterPreset: 12,
      padVel: 58, leadVel: 92, bassVel: 88, counterVel: 52,
      kickVel: 95, snareVel: 82,
    );
  }

  // DESERT (lvl4) — exotic, Phrygian. Dm - Ebmaj7 - Dm - A7. 100 BPM.
  Uint8List _mkDesert({int transpose = 0, double bpm = 100}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([50,1,16, 51,2,16, 50,1,16, 45,4,16], 4), transpose),
      bassSeq: _tp(_rep([
        38,4, 45,4, 38,4, 45,4, 39,4, 46,4, 39,4, 46,4,
        38,4, 45,4, 38,4, 45,4, 45,4, 52,4, 45,4, 52,4,
      ], 4), transpose),
      leadSeq: _tp([
        // A: ornamental, half-step movement
        74,3, 75,1, 77,4, 74,4, 72,4,  74,2, 75,2, 77,4, 79,8,
        77,3, 79,1, 80,4, 79,4, 77,4,  76,4, 74,4, 72,8,
        74,2, 77,2, 79,4, 81,4, 79,4,  77,4, 74,4, 73,4, 74,4,
        72,4, 74,4, 77,4, 74,4,  74,16,
        // B: more flowing, higher
        72,4, 74,3, 75,1, 77,4, 74,4,  75,4, 77,4, 79,4, 77,4,
        74,3, 72,1, 74,4, 77,4, 74,4,  81,4, 77,4, 74,4, 73,4,
        74,2, 75,2, 77,4, 79,4, 77,4,  79,4, 77,4, 75,4, 74,4,
        77,4, 74,4, 72,4, 69,4,  74,3, 73,1, 74,4, 72,4, 74,4,
      ], transpose),
      counterSeq: _tp(_rep([
        50,2, 53,2, 57,2, 53,2, 50,2, 53,2, 57,2, 53,2,
        51,2, 55,2, 58,2, 55,2, 51,2, 55,2, 58,2, 55,2,
        50,2, 53,2, 57,2, 53,2, 50,2, 53,2, 57,2, 53,2,
        45,2, 49,2, 52,2, 49,2, 45,2, 49,2, 52,2, 49,2,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,0,0,4, 0,0,2,0, 1,0,4,0, 2,0,4,4], 7),
        1,0,0,2, 2,0,2,0, 1,2,0,2, 17,0,8,0,
        ..._rep([1,0,0,4, 0,0,2,4, 1,0,4,0, 2,0,0,4], 7),
        1,0,4,2, 2,0,2,4, 1,2,2,0, 17,0,0,0,
      ],
      padPreset: 48, leadPreset: 68, bassPreset: 35,
      counterPreset: 11,
      padVel: 58, leadVel: 88, bassVel: 78, counterVel: 48,
    );
  }

  // SPACE (lvl5) — ethereal, floating. Cmaj9 - Amin9 - Fmaj7 - Gsus. 84 BPM.
  Uint8List _mkSpace({int transpose = 0, double bpm = 84}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([60,7,16, 57,6,16, 53,2,16, 55,5,16], 4), transpose),
      bassSeq: _tp(_rep([48,8, 48,8, 45,8, 45,8, 41,8, 41,8, 43,8, 43,8], 4), transpose),
      leadSeq: _tp([
        // A: floating, spacious
        79,6, 83,2, 84,8,  81,6, 79,2, 76,8,
        77,4, 79,4, 81,8,  74,4, 79,4, 83,8,
        84,8, 79,8,  81,8, 77,8,
        79,4, 81,4, 84,4, 88,4,  86,16,
        // B: higher, ethereal
        84,8, 83,4, 81,4,  81,4, 79,4, 76,8,
        77,4, 79,4, 84,8,  83,4, 81,4, 79,8,
        76,8, 79,4, 81,4,  84,4, 81,4, 79,8,
        77,4, 81,4, 84,4, 81,4,  79,4, 81,4, 84,4, 86,4,
      ], transpose),
      counterSeq: _tp(_rep([
        60,4, 0,4, 64,4, 0,4,
        57,4, 0,4, 60,4, 0,4,
        53,4, 0,4, 57,4, 0,4,
        55,4, 0,4, 62,4, 0,4,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,0,0,0, 0,0,4,0, 0,0,0,0, 0,0,4,0], 7),
        1,0,0,0, 0,0,4,0, 0,0,8,0, 17,0,0,0,
        ..._rep([1,0,0,0, 0,0,4,0, 0,0,0,4, 0,0,4,0], 7),
        1,0,0,0, 4,0,4,0, 0,0,8,0, 17,0,0,0,
      ],
      padPreset: 52, leadPreset: 88, bassPreset: 39,
      counterPreset: 46,
      padVel: 55, leadVel: 78, bassVel: 68, counterVel: 42,
      kickVel: 65, hatVel: 40,
    );
  }

  // BOSS — aggressive, menacing. Em - C - D - B7. 155 BPM. Distorted organ + power bass.
  Uint8List _mkBoss({int transpose = 0, double bpm = 155}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([52,1,16, 48,0,16, 50,0,16, 47,4,16], 4), transpose),
      bassSeq: _tp(_rep([
        28,1, 28,1, 40,2, 28,2, 28,1, 28,1, 40,2, 28,2,
        24,1, 24,1, 36,2, 24,2, 24,1, 24,1, 36,2, 24,2,
        26,1, 26,1, 38,2, 26,2, 26,1, 26,1, 38,2, 26,2,
        35,1, 35,1, 47,2, 35,2, 35,1, 35,1, 47,2, 35,2,
      ], 4), transpose),
      leadSeq: _tp([
        // A: menacing, chromatic stabs
        76,2, 75,2, 72,2, 71,2, 67,4, 64,4,
        76,2, 79,2, 80,4, 76,4, 72,4,
        71,2, 72,2, 76,2, 79,2, 83,4, 80,4,
        79,2, 76,2, 72,4, 71,4, 67,4,
        // A repeat with variation
        76,2, 75,2, 72,2, 71,2, 67,4, 71,4,
        72,2, 76,2, 79,4, 83,4, 80,4,
        76,1, 79,1, 83,2, 80,2, 76,2, 72,4, 71,4,
        67,2, 71,2, 72,4, 76,4, 67,4,
        // B: relentless, higher register
        83,2, 84,2, 83,2, 80,2, 76,4, 72,4,
        79,2, 80,2, 83,4, 84,2, 83,2, 79,4,
        76,2, 79,2, 83,2, 84,2, 88,4, 83,4,
        84,2, 83,2, 80,2, 76,2, 72,4, 71,4,
        79,2, 83,2, 84,4, 88,4, 84,4,
        83,2, 80,2, 76,4, 79,4, 76,4,
        72,2, 76,2, 79,4, 76,4, 72,4,
        71,2, 67,2, 64,4, 67,4, 64,4,
      ], transpose),
      counterSeq: _tp(_rep([
        52,1, 55,1, 59,1, 55,1, 52,1, 55,1, 59,1, 55,1,
        52,1, 55,1, 59,1, 55,1, 52,1, 55,1, 59,1, 55,1,
        48,1, 52,1, 55,1, 52,1, 48,1, 52,1, 55,1, 52,1,
        47,1, 51,1, 55,1, 51,1, 47,1, 51,1, 55,1, 51,1,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,2,4, 1,4,2,4], 7),
        1,2,1,2, 2,2,1,2, 2,4,2,4, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,1,2, 1,4,2,4, 1,4,2,4], 7),
        2,2,1,2, 1,2,2,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 19, leadPreset: 30, bassPreset: 38,
      counterPreset: 60,
      padVel: 70, leadVel: 100, bassVel: 95, counterVel: 58,
      kickVel: 100, snareVel: 90, hatVel: 65,
    );
  }

  // BOSS 2 — thrash metal fury, E minor, 170 BPM
  Uint8List _mkBoss2() {
    return _renderSf(
      bpm: 170,
      padSeq: _tpad(_rep([52,1,16, 55,0,16, 48,0,16, 43,4,16], 4), 0),
      bassSeq: _tp(_rep([
        28,1, 28,1, 28,1, 28,1, 40,2, 28,2, 28,1, 28,1,
        26,1, 26,1, 26,1, 26,1, 38,2, 26,2, 26,1, 26,1,
        24,1, 24,1, 24,1, 24,1, 36,2, 24,2, 24,1, 24,1,
        31,1, 31,1, 31,1, 31,1, 43,2, 31,2, 31,1, 31,1,
      ], 4), 0),
      leadSeq: _tp([
        76,1, 76,1, 79,2, 83,2, 84,2, 83,2, 79,2, 76,2,
        74,1, 74,1, 76,2, 79,2, 83,4, 79,4,
        72,1, 72,1, 76,2, 79,2, 83,2, 84,2, 83,2, 79,2,
        76,2, 74,2, 72,4, 71,4, 67,4,
        88,2, 87,2, 84,2, 83,2, 79,4, 76,4,
        83,1, 84,1, 88,2, 91,4, 88,2, 84,2, 83,4,
        79,2, 83,2, 84,2, 88,2, 91,4, 88,4,
        84,2, 83,2, 79,4, 76,4, 72,4,
        76,1, 79,1, 83,1, 84,1, 88,2, 84,2, 83,2, 79,2, 76,2, 72,2,
        71,2, 67,2, 64,4, 67,4, 71,4,
        76,2, 79,2, 83,4, 84,4, 88,4,
        84,2, 83,2, 79,4, 76,4, 72,4,
        76,1, 76,1, 79,2, 83,2, 84,4, 83,4,
        79,2, 76,2, 72,4, 71,4, 67,4,
        64,2, 67,2, 71,4, 76,4, 72,4,
        67,2, 64,2, 60,4, 64,4, 67,4,
      ], 0),
      counterSeq: _tp(_rep([
        52,1, 55,1, 59,1, 64,1, 59,1, 55,1, 52,1, 55,1,
        50,1, 54,1, 57,1, 62,1, 57,1, 54,1, 50,1, 54,1,
        48,1, 52,1, 55,1, 60,1, 55,1, 52,1, 48,1, 52,1,
        55,1, 59,1, 62,1, 67,1, 62,1, 59,1, 55,1, 59,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,2,1,2, 2,4,1,4, 1,4,2,4], 7),
        1,2,1,2, 1,2,1,2, 2,2,2,2, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,1,2, 1,2,2,4, 1,4,2,4], 7),
        2,2,1,2, 1,2,2,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 29, leadPreset: 81, bassPreset: 38,
      counterPreset: 46,
      padVel: 72, leadVel: 105, bassVel: 100, counterVel: 55,
      kickVel: 105, snareVel: 95, hatVel: 70,
    );
  }

  // BOSS 3 — dark synth chase, C# minor, 160 BPM
  Uint8List _mkBoss3() {
    return _renderSf(
      bpm: 160,
      padSeq: _tpad(_rep([49,1,16, 52,0,16, 44,0,16, 47,4,16], 4), 0),
      bassSeq: _tp(_rep([
        25,1, 25,1, 37,2, 25,2, 25,1, 25,1, 37,2, 25,2,
        28,1, 28,1, 40,2, 28,2, 28,1, 28,1, 40,2, 28,2,
        23,1, 23,1, 35,2, 23,2, 23,1, 23,1, 35,2, 23,2,
        25,1, 25,1, 37,2, 25,2, 25,1, 25,1, 37,2, 25,2,
      ], 4), 0),
      leadSeq: _tp([
        73,2, 76,2, 80,4, 85,4, 80,4,
        76,2, 73,2, 68,4, 73,4, 76,4,
        80,2, 85,2, 88,4, 85,2, 80,2, 76,4,
        73,2, 76,2, 80,4, 73,4, 68,4,
        73,1, 76,1, 80,2, 85,2, 88,4, 85,4,
        80,1, 76,1, 73,2, 68,4, 73,4, 76,4,
        80,2, 85,2, 88,2, 92,2, 88,4, 85,4,
        80,2, 76,2, 73,4, 68,4, 61,4,
        85,2, 88,2, 92,4, 88,4, 85,4,
        80,2, 76,2, 73,4, 76,4, 80,4,
        85,1, 88,1, 92,2, 88,2, 85,2, 80,2, 76,4,
        73,2, 68,2, 61,4, 73,4, 68,4,
        73,2, 76,2, 80,4, 85,4, 88,4,
        92,4, 88,4, 85,4, 80,4,
        76,2, 73,2, 68,4, 61,4, 68,4,
        73,4, 76,4, 80,4, 73,4,
      ], 0),
      counterSeq: _tp(_rep([
        49,1, 52,1, 56,1, 61,1, 56,1, 52,1, 49,1, 52,1,
        52,1, 56,1, 59,1, 64,1, 59,1, 56,1, 52,1, 56,1,
        47,1, 51,1, 54,1, 59,1, 54,1, 51,1, 47,1, 51,1,
        49,1, 52,1, 56,1, 61,1, 56,1, 52,1, 49,1, 52,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,2, 1,4,2,4, 1,4,2,4], 7),
        1,2,1,2, 2,4,2,4, 1,2,1,2, 17,0,8,0,
        ..._rep([1,4,2,4, 1,2,2,4, 1,4,2,4, 1,4,1,2], 7),
        2,2,2,2, 1,2,1,2, 2,4,2,4, 17,0,0,0,
      ],
      padPreset: 50, leadPreset: 80, bassPreset: 38,
      counterPreset: 62,
      padVel: 68, leadVel: 100, bassVel: 95, counterVel: 52,
      kickVel: 100, snareVel: 90, hatVel: 65,
    );
  }

  // BOSS 4 — punk speed, D minor, 175 BPM
  Uint8List _mkBoss4() {
    return _renderSf(
      bpm: 175,
      padSeq: _tpad(_rep([50,1,16, 53,0,16, 45,0,16, 48,4,16], 4), 0),
      bassSeq: _tp(_rep([
        26,1, 26,1, 26,1, 38,1, 26,2, 26,1, 26,1, 38,2,
        29,1, 29,1, 29,1, 41,1, 29,2, 29,1, 29,1, 41,2,
        24,1, 24,1, 24,1, 36,1, 24,2, 24,1, 24,1, 36,2,
        31,1, 31,1, 31,1, 43,1, 31,2, 31,1, 31,1, 43,2,
      ], 4), 0),
      leadSeq: _tp([
        74,1, 77,1, 81,2, 86,4, 81,2, 77,2,
        74,1, 74,1, 77,2, 81,4, 77,4,
        72,1, 74,1, 77,2, 81,2, 86,2, 89,2, 86,4,
        81,2, 77,2, 74,4, 72,4, 69,4,
        74,2, 77,2, 81,2, 86,2, 89,4, 86,4,
        81,1, 77,1, 74,2, 69,4, 74,4, 77,4,
        81,1, 86,1, 89,2, 93,4, 89,2, 86,2, 81,2,
        77,2, 74,2, 69,4, 65,4, 62,4,
        86,1, 89,1, 93,2, 89,2, 86,2, 81,2, 77,4,
        74,2, 77,2, 81,4, 86,4, 81,4,
        77,1, 74,1, 69,2, 65,4, 69,4, 74,4,
        77,2, 81,2, 86,4, 89,4, 86,4,
        81,2, 77,2, 74,4, 69,4, 65,4,
        62,2, 65,2, 69,4, 74,4, 69,4,
        74,1, 77,1, 81,2, 86,4, 81,4,
        77,2, 74,2, 69,4, 74,4, 77,4,
      ], 0),
      counterSeq: _tp(_rep([
        50,1, 53,1, 57,1, 62,1, 57,1, 53,1, 50,1, 53,1,
        53,1, 57,1, 60,1, 65,1, 60,1, 57,1, 53,1, 57,1,
        48,1, 52,1, 55,1, 60,1, 55,1, 52,1, 48,1, 52,1,
        55,1, 59,1, 62,1, 67,1, 62,1, 59,1, 55,1, 59,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,2,2,4, 1,2,1,2, 2,4,1,2, 1,2,2,4], 7),
        1,2,1,2, 1,2,1,2, 2,2,2,2, 17,0,8,0,
        ..._rep([1,2,2,4, 1,4,1,2, 1,2,2,4, 1,2,2,2], 7),
        2,2,1,2, 2,2,1,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 19, leadPreset: 25, bassPreset: 34,
      counterPreset: 60,
      padVel: 70, leadVel: 105, bassVel: 100, counterVel: 55,
      kickVel: 110, snareVel: 95, hatVel: 72,
    );
  }

  // BOSS 5 — doom groove, Bb minor, 145 BPM
  Uint8List _mkBoss5() {
    return _renderSf(
      bpm: 145,
      padSeq: _tpad(_rep([46,1,16, 49,0,16, 53,0,16, 42,4,16], 4), 0),
      bassSeq: _tp(_rep([
        22,1, 22,2, 34,2, 22,2, 22,1, 34,2, 22,2, 22,2,
        25,1, 25,2, 37,2, 25,2, 25,1, 37,2, 25,2, 25,2,
        27,1, 27,2, 39,2, 27,2, 27,1, 39,2, 27,2, 27,2,
        30,1, 30,2, 42,2, 30,2, 30,1, 42,2, 30,2, 30,2,
      ], 4), 0),
      leadSeq: _tp([
        70,4, 73,4, 77,4, 82,4,
        77,2, 73,2, 70,4, 65,4, 70,4,
        73,2, 77,2, 82,4, 85,4, 82,4,
        77,2, 73,2, 70,4, 65,4, 61,4,
        70,2, 73,2, 77,4, 82,4, 85,4,
        89,4, 85,4, 82,4, 77,4,
        73,2, 70,2, 65,4, 61,4, 58,4,
        61,2, 65,2, 70,4, 73,4, 70,4,
        82,2, 85,2, 89,4, 85,4, 82,4,
        77,2, 73,2, 70,4, 73,4, 77,4,
        82,4, 85,4, 89,4, 94,4,
        89,2, 85,2, 82,4, 77,4, 73,4,
        70,2, 65,2, 61,4, 65,4, 70,4,
        73,4, 77,4, 82,4, 77,4,
        73,2, 70,2, 65,4, 61,4, 58,4,
        61,4, 65,4, 70,4, 73,4,
      ], 0),
      counterSeq: _tp(_rep([
        46,2, 49,2, 53,2, 58,2, 53,2, 49,2, 46,2, 49,2,
        49,2, 53,2, 56,2, 61,2, 56,2, 53,2, 49,2, 53,2,
        51,2, 55,2, 58,2, 63,2, 58,2, 55,2, 51,2, 55,2,
        54,2, 58,2, 61,2, 66,2, 61,2, 58,2, 54,2, 58,2,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,2,4, 1,4,2,4], 7),
        1,4,2,4, 1,2,1,2, 2,4,2,4, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,4,2, 1,4,2,4, 1,4,2,4], 7),
        2,4,1,4, 1,2,2,2, 2,4,1,4, 17,0,0,0,
      ],
      padPreset: 92, leadPreset: 57, bassPreset: 33,
      counterPreset: 46,
      padVel: 75, leadVel: 95, bassVel: 95, counterVel: 50,
      kickVel: 100, snareVel: 88, hatVel: 60,
    );
  }

  // BOSS 6 — frantic 8-bit, F# minor, 168 BPM
  Uint8List _mkBoss6() {
    return _renderSf(
      bpm: 168,
      padSeq: _tpad(_rep([54,1,16, 57,0,16, 49,0,16, 52,4,16], 4), 0),
      bassSeq: _tp(_rep([
        30,1, 30,1, 42,2, 30,1, 30,1, 42,2, 30,2, 30,2,
        33,1, 33,1, 45,2, 33,1, 33,1, 45,2, 33,2, 33,2,
        28,1, 28,1, 40,2, 28,1, 28,1, 40,2, 28,2, 28,2,
        25,1, 25,1, 37,2, 25,1, 25,1, 37,2, 25,2, 25,2,
      ], 4), 0),
      leadSeq: _tp([
        78,1, 81,1, 85,2, 90,2, 85,2, 81,2, 78,2,
        78,1, 78,1, 81,2, 85,4, 81,4,
        85,1, 90,1, 93,2, 90,2, 85,2, 81,2, 78,2,
        81,2, 78,2, 73,4, 69,4, 66,4,
        78,1, 81,1, 85,2, 90,4, 93,4,
        90,1, 85,1, 81,2, 78,4, 73,4, 69,4,
        66,1, 69,1, 73,2, 78,4, 81,4, 85,4,
        90,2, 85,2, 81,4, 78,4, 73,4,
        90,1, 93,1, 97,2, 93,2, 90,2, 85,4,
        81,2, 78,2, 73,4, 78,4, 81,4,
        85,1, 81,1, 78,2, 73,4, 69,4, 66,4,
        69,2, 73,2, 78,4, 81,4, 78,4,
        85,2, 90,2, 93,4, 90,4, 85,4,
        81,2, 78,2, 73,4, 69,4, 66,4,
        73,1, 78,1, 81,2, 85,4, 81,4,
        78,2, 73,2, 69,4, 66,4, 69,4,
      ], 0),
      counterSeq: _tp(_rep([
        54,1, 57,1, 61,1, 66,1, 61,1, 57,1, 54,1, 57,1,
        57,1, 61,1, 64,1, 69,1, 64,1, 61,1, 57,1, 61,1,
        52,1, 56,1, 59,1, 64,1, 59,1, 56,1, 52,1, 56,1,
        49,1, 53,1, 56,1, 61,1, 56,1, 53,1, 49,1, 53,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,2,2,4, 1,2,2,2, 1,2,2,4, 1,4,2,4], 7),
        1,2,1,2, 2,2,1,2, 2,2,2,2, 17,0,8,0,
        ..._rep([1,2,2,4, 1,4,1,2, 1,2,2,4, 1,2,2,4], 7),
        2,2,1,2, 1,2,2,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 81, leadPreset: 80, bassPreset: 38,
      counterPreset: 46,
      padVel: 65, leadVel: 100, bassVel: 95, counterVel: 58,
      kickVel: 105, snareVel: 92, hatVel: 68,
    );
  }

  // BOSS 7 — industrial stomp, G minor, 150 BPM
  Uint8List _mkBoss7() {
    return _renderSf(
      bpm: 150,
      padSeq: _tpad(_rep([55,1,16, 58,0,16, 50,0,16, 46,4,16], 4), 0),
      bassSeq: _tp(_rep([
        31,1, 31,1, 31,2, 43,2, 31,2, 31,1, 31,1, 43,2,
        27,1, 27,1, 27,2, 39,2, 27,2, 27,1, 27,1, 39,2,
        29,1, 29,1, 29,2, 41,2, 29,2, 29,1, 29,1, 41,2,
        34,1, 34,1, 34,2, 46,2, 34,2, 34,1, 34,1, 46,2,
      ], 4), 0),
      leadSeq: _tp([
        79,4, 82,2, 86,2, 91,4, 86,4,
        82,2, 79,2, 74,4, 70,4, 67,4,
        79,2, 82,2, 86,4, 91,4, 94,4,
        91,2, 86,2, 82,4, 79,4, 74,4,
        67,2, 70,2, 74,4, 79,4, 82,4,
        86,2, 91,2, 94,4, 91,4, 86,4,
        82,2, 79,2, 74,4, 70,4, 67,4,
        70,2, 74,2, 79,4, 82,4, 79,4,
        91,2, 94,2, 98,4, 94,4, 91,4,
        86,2, 82,2, 79,4, 74,4, 70,4,
        67,2, 70,2, 74,4, 79,4, 82,4,
        86,4, 91,4, 86,4, 82,4,
        79,2, 74,2, 70,4, 67,4, 63,4,
        67,2, 70,2, 74,4, 79,4, 74,4,
        70,2, 67,2, 63,4, 67,4, 70,4,
        74,4, 79,4, 82,4, 79,4,
      ], 0),
      counterSeq: _tp(_rep([
        55,1, 58,1, 62,1, 67,1, 62,1, 58,1, 55,1, 58,1,
        51,1, 55,1, 58,1, 63,1, 58,1, 55,1, 51,1, 55,1,
        53,1, 57,1, 60,1, 65,1, 60,1, 57,1, 53,1, 57,1,
        58,1, 62,1, 65,1, 70,1, 65,1, 62,1, 58,1, 62,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,2,4, 1,4,4,2], 7),
        1,2,1,2, 2,4,1,4, 2,2,2,2, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,4,2, 1,4,2,4], 7),
        2,4,1,4, 2,4,2,4, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 90, leadPreset: 29, bassPreset: 33,
      counterPreset: 62,
      padVel: 72, leadVel: 98, bassVel: 100, counterVel: 52,
      kickVel: 110, snareVel: 95, hatVel: 62,
    );
  }

  // BOSS 8 — breakneck rave, A minor, 165 BPM
  Uint8List _mkBoss8() {
    return _renderSf(
      bpm: 165,
      padSeq: _tpad(_rep([57,1,16, 60,0,16, 52,0,16, 48,4,16], 4), 0),
      bassSeq: _tp(_rep([
        33,1, 33,1, 45,1, 33,1, 33,1, 45,2, 33,2, 33,2,
        36,1, 36,1, 48,1, 36,1, 36,1, 48,2, 36,2, 36,2,
        31,1, 31,1, 43,1, 31,1, 31,1, 43,2, 31,2, 31,2,
        28,1, 28,1, 40,1, 28,1, 28,1, 40,2, 28,2, 28,2,
      ], 4), 0),
      leadSeq: _tp([
        81,1, 84,1, 88,2, 93,4, 88,2, 84,2,
        81,2, 76,2, 72,4, 69,4, 72,4,
        76,1, 81,1, 84,2, 88,2, 93,2, 88,2, 84,4,
        81,2, 76,2, 72,4, 69,4, 64,4,
        81,2, 84,2, 88,4, 93,4, 96,4,
        93,1, 88,1, 84,2, 81,4, 76,4, 72,4,
        69,1, 72,1, 76,2, 81,4, 84,4, 88,4,
        93,2, 88,2, 84,4, 81,4, 76,4,
        93,1, 96,1, 100,2, 96,2, 93,2, 88,4,
        84,2, 81,2, 76,4, 72,4, 69,4,
        64,2, 69,2, 72,4, 76,4, 81,4,
        84,2, 88,2, 93,4, 88,4, 84,4,
        81,1, 76,1, 72,2, 69,4, 64,4, 69,4,
        72,2, 76,2, 81,4, 84,4, 81,4,
        76,2, 72,2, 69,4, 64,4, 69,4,
        72,4, 76,4, 81,4, 84,4,
      ], 0),
      counterSeq: _tp(_rep([
        57,1, 60,1, 64,1, 69,1, 64,1, 60,1, 57,1, 60,1,
        60,1, 64,1, 67,1, 72,1, 67,1, 64,1, 60,1, 64,1,
        55,1, 59,1, 62,1, 67,1, 62,1, 59,1, 55,1, 59,1,
        52,1, 56,1, 59,1, 64,1, 59,1, 56,1, 52,1, 56,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,2,2,4, 1,2,2,2, 1,4,2,2, 1,2,2,4], 7),
        1,2,1,2, 2,2,1,2, 1,2,2,2, 17,0,8,0,
        ..._rep([1,4,2,2, 1,2,2,4, 1,2,1,2, 2,4,2,4], 7),
        2,2,2,2, 1,2,1,2, 2,2,2,2, 17,0,0,0,
      ],
      padPreset: 51, leadPreset: 81, bassPreset: 38,
      counterPreset: 60,
      padVel: 68, leadVel: 102, bassVel: 98, counterVel: 55,
      kickVel: 105, snareVel: 92, hatVel: 70,
    );
  }

  // BOSS 9 — death march, F minor, 140 BPM
  Uint8List _mkBoss9() {
    return _renderSf(
      bpm: 140,
      padSeq: _tpad(_rep([53,1,16, 56,0,16, 48,0,16, 44,4,16], 4), 0),
      bassSeq: _tp(_rep([
        29,1, 29,2, 41,2, 29,2, 29,1, 41,2, 29,1, 29,2,
        32,1, 32,2, 44,2, 32,2, 32,1, 44,2, 32,1, 32,2,
        27,1, 27,2, 39,2, 27,2, 27,1, 39,2, 27,1, 27,2,
        24,1, 24,2, 36,2, 24,2, 24,1, 36,2, 24,1, 24,2,
      ], 4), 0),
      leadSeq: _tp([
        77,4, 80,4, 84,4, 89,4,
        84,2, 80,2, 77,4, 72,4, 68,4,
        77,2, 80,2, 84,4, 89,4, 92,4,
        89,2, 84,2, 80,4, 77,4, 72,4,
        68,2, 72,2, 77,4, 80,4, 84,4,
        89,2, 92,2, 96,4, 92,4, 89,4,
        84,2, 80,2, 77,4, 72,4, 68,4,
        65,2, 68,2, 72,4, 77,4, 72,4,
        89,2, 92,2, 96,4, 92,4, 89,4,
        84,2, 80,2, 77,4, 80,4, 84,4,
        89,4, 92,4, 96,4, 92,4,
        89,2, 84,2, 80,4, 77,4, 72,4,
        68,4, 72,4, 77,4, 80,4,
        84,2, 89,2, 92,4, 89,4, 84,4,
        80,2, 77,2, 72,4, 68,4, 65,4,
        68,4, 72,4, 77,4, 80,4,
      ], 0),
      counterSeq: _tp(_rep([
        53,2, 56,2, 60,2, 65,2, 60,2, 56,2, 53,2, 56,2,
        56,2, 60,2, 63,2, 68,2, 63,2, 60,2, 56,2, 60,2,
        51,2, 55,2, 58,2, 63,2, 58,2, 55,2, 51,2, 55,2,
        48,2, 52,2, 55,2, 60,2, 55,2, 52,2, 48,2, 52,2,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,2,4, 1,4,2,4], 7),
        1,2,1,2, 2,4,1,4, 2,4,2,4, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,4,2, 1,4,2,4], 7),
        2,4,1,4, 2,2,2,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 61, leadPreset: 56, bassPreset: 34,
      counterPreset: 46,
      padVel: 75, leadVel: 95, bassVel: 92, counterVel: 50,
      kickVel: 100, snareVel: 88, hatVel: 58,
    );
  }

  // BOSS 10 — chaos blitz, Eb minor, 180 BPM
  Uint8List _mkBoss10() {
    return _renderSf(
      bpm: 180,
      padSeq: _tpad(_rep([51,1,16, 54,0,16, 46,0,16, 42,4,16], 4), 0),
      bassSeq: _tp(_rep([
        27,1, 27,1, 27,1, 27,1, 39,2, 27,1, 27,1, 39,2,
        30,1, 30,1, 30,1, 30,1, 42,2, 30,1, 30,1, 42,2,
        25,1, 25,1, 25,1, 25,1, 37,2, 25,1, 25,1, 37,2,
        22,1, 22,1, 22,1, 22,1, 34,2, 22,1, 22,1, 34,2,
      ], 4), 0),
      leadSeq: _tp([
        75,1, 78,1, 82,2, 87,2, 90,2, 87,2, 82,2,
        78,1, 75,1, 70,2, 66,4, 70,4,
        75,1, 78,1, 82,1, 87,1, 90,2, 94,2, 90,2, 87,2, 82,2,
        78,2, 75,2, 70,4, 66,4,
        90,1, 94,1, 97,2, 94,2, 90,2, 87,2, 82,4,
        78,1, 75,1, 70,2, 66,4, 63,4, 66,4,
        70,1, 75,1, 78,2, 82,4, 87,4, 90,4,
        94,2, 90,2, 87,4, 82,4, 78,4,
        75,1, 78,1, 82,1, 87,1, 90,2, 87,2, 82,2, 78,4,
        75,2, 70,2, 66,4, 63,4, 66,4,
        70,2, 75,2, 78,4, 82,4, 87,4,
        90,2, 94,2, 97,4, 94,4, 90,4,
        87,1, 82,1, 78,2, 75,4, 70,4, 66,4,
        63,2, 66,2, 70,4, 75,4, 70,4,
        66,1, 70,1, 75,2, 78,4, 82,4,
        87,4, 82,4, 78,4, 75,4,
      ], 0),
      counterSeq: _tp(_rep([
        51,1, 54,1, 58,1, 63,1, 58,1, 54,1, 51,1, 54,1,
        54,1, 58,1, 61,1, 66,1, 61,1, 58,1, 54,1, 58,1,
        49,1, 53,1, 56,1, 61,1, 56,1, 53,1, 49,1, 53,1,
        46,1, 50,1, 53,1, 58,1, 53,1, 50,1, 46,1, 50,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,2,2,2, 1,2,1,2, 2,2,1,2, 1,2,2,2], 7),
        1,2,1,2, 1,2,1,2, 2,2,2,2, 17,0,8,0,
        ..._rep([1,2,2,2, 1,2,2,2, 1,2,1,2, 2,2,2,2], 7),
        2,2,1,2, 1,2,2,2, 2,2,1,2, 17,0,0,0,
      ],
      padPreset: 29, leadPreset: 25, bassPreset: 38,
      counterPreset: 62,
      padVel: 70, leadVel: 108, bassVel: 100, counterVel: 58,
      kickVel: 110, snareVel: 98, hatVel: 75,
    );
  }

  // BOSS 11 — glitch assault, B minor, 162 BPM
  Uint8List _mkBoss11() {
    return _renderSf(
      bpm: 162,
      padSeq: _tpad(_rep([59,1,16, 62,0,16, 54,0,16, 50,4,16], 4), 0),
      bassSeq: _tp(_rep([
        35,1, 35,1, 47,2, 35,1, 35,1, 47,1, 35,1, 35,2,
        30,1, 30,1, 42,2, 30,1, 30,1, 42,1, 30,1, 30,2,
        33,1, 33,1, 45,2, 33,1, 33,1, 45,1, 33,1, 33,2,
        38,1, 38,1, 50,2, 38,1, 38,1, 50,1, 38,1, 38,2,
      ], 4), 0),
      leadSeq: _tp([
        83,2, 86,2, 90,4, 95,4, 90,4,
        86,1, 83,1, 78,2, 74,4, 71,4, 74,4,
        78,2, 83,2, 86,4, 90,4, 95,4,
        90,1, 86,1, 83,2, 78,4, 74,4, 71,4,
        83,1, 86,1, 90,2, 95,2, 98,2, 95,4,
        90,2, 86,2, 83,4, 78,4, 74,4,
        71,1, 74,1, 78,2, 83,4, 86,4, 90,4,
        95,2, 90,2, 86,4, 83,4, 78,4,
        95,2, 98,2, 102,4, 98,4, 95,4,
        90,2, 86,2, 83,4, 86,4, 90,4,
        95,4, 90,4, 86,4, 83,4,
        78,2, 74,2, 71,4, 74,4, 78,4,
        83,1, 86,1, 90,2, 95,4, 90,4,
        86,2, 83,2, 78,4, 74,4, 71,4,
        74,2, 78,2, 83,4, 78,4, 74,4,
        71,4, 74,4, 78,4, 83,4,
      ], 0),
      counterSeq: _tp(_rep([
        59,1, 62,1, 66,1, 71,1, 66,1, 62,1, 59,1, 62,1,
        54,1, 58,1, 61,1, 66,1, 61,1, 58,1, 54,1, 58,1,
        57,1, 61,1, 64,1, 69,1, 64,1, 61,1, 57,1, 61,1,
        62,1, 66,1, 69,1, 74,1, 69,1, 66,1, 62,1, 66,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,2,2,2, 1,4,2,4, 1,4,2,2], 7),
        1,2,1,2, 2,2,2,2, 1,2,1,2, 17,0,8,0,
        ..._rep([1,2,2,4, 1,4,2,2, 1,2,2,4, 1,4,1,2], 7),
        2,2,1,2, 2,2,1,2, 2,2,2,2, 17,0,0,0,
      ],
      padPreset: 50, leadPreset: 30, bassPreset: 34,
      counterPreset: 46,
      padVel: 70, leadVel: 102, bassVel: 98, counterVel: 55,
      kickVel: 105, snareVel: 92, hatVel: 68,
    );
  }

  // BOSS 12 — war drums, Ab minor, 148 BPM
  Uint8List _mkBoss12() {
    return _renderSf(
      bpm: 148,
      padSeq: _tpad(_rep([56,1,16, 59,0,16, 51,0,16, 47,4,16], 4), 0),
      bassSeq: _tp(_rep([
        32,1, 32,2, 44,2, 32,1, 32,2, 44,2, 32,2, 32,1,
        35,1, 35,2, 47,2, 35,1, 35,2, 47,2, 35,2, 35,1,
        30,1, 30,2, 42,2, 30,1, 30,2, 42,2, 30,2, 30,1,
        27,1, 27,2, 39,2, 27,1, 27,2, 39,2, 27,2, 27,1,
      ], 4), 0),
      leadSeq: _tp([
        80,4, 83,4, 87,4, 92,4,
        87,2, 83,2, 80,4, 75,4, 71,4,
        80,2, 83,2, 87,4, 92,4, 95,4,
        92,2, 87,2, 83,4, 80,4, 75,4,
        71,2, 75,2, 80,4, 83,4, 87,4,
        92,4, 95,4, 92,4, 87,4,
        83,2, 80,2, 75,4, 71,4, 68,4,
        71,2, 75,2, 80,4, 83,4, 80,4,
        92,2, 95,2, 99,4, 95,4, 92,4,
        87,2, 83,2, 80,4, 83,4, 87,4,
        92,4, 87,4, 83,4, 80,4,
        75,2, 71,2, 68,4, 71,4, 75,4,
        80,2, 83,2, 87,4, 92,4, 87,4,
        83,2, 80,2, 75,4, 71,4, 68,4,
        71,4, 75,4, 80,4, 75,4,
        71,4, 68,4, 71,4, 75,4,
      ], 0),
      counterSeq: _tp(_rep([
        56,2, 59,2, 63,2, 68,2, 63,2, 59,2, 56,2, 59,2,
        59,2, 63,2, 66,2, 71,2, 66,2, 63,2, 59,2, 63,2,
        54,2, 58,2, 61,2, 66,2, 61,2, 58,2, 54,2, 58,2,
        51,2, 55,2, 58,2, 63,2, 58,2, 55,2, 51,2, 55,2,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,4, 1,2,2,4, 1,4,2,4], 7),
        1,4,2,4, 1,2,1,2, 2,4,2,4, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,4,2, 1,4,2,4, 1,4,2,4], 7),
        2,4,1,4, 1,2,2,2, 2,4,1,4, 17,0,0,0,
      ],
      padPreset: 92, leadPreset: 57, bassPreset: 33,
      counterPreset: 60,
      padVel: 78, leadVel: 96, bassVel: 95, counterVel: 52,
      kickVel: 110, snareVel: 95, hatVel: 60,
    );
  }

  // BOSS 13 — speed demon, C minor, 176 BPM
  Uint8List _mkBoss13() {
    return _renderSf(
      bpm: 176,
      padSeq: _tpad(_rep([48,1,16, 51,0,16, 55,0,16, 43,4,16], 4), 0),
      bassSeq: _tp(_rep([
        24,1, 24,1, 24,1, 36,1, 24,1, 24,1, 36,2, 24,2,
        27,1, 27,1, 27,1, 39,1, 27,1, 27,1, 39,2, 27,2,
        22,1, 22,1, 22,1, 34,1, 22,1, 22,1, 34,2, 22,2,
        31,1, 31,1, 31,1, 43,1, 31,1, 31,1, 43,2, 31,2,
      ], 4), 0),
      leadSeq: _tp([
        72,1, 75,1, 79,2, 84,2, 87,2, 84,2, 79,2,
        75,1, 72,1, 67,2, 63,4, 67,4,
        72,1, 75,1, 79,1, 84,1, 87,2, 91,2, 87,2, 84,4,
        79,2, 75,2, 72,4, 67,4,
        87,1, 91,1, 96,2, 91,2, 87,2, 84,2, 79,4,
        75,1, 72,1, 67,2, 63,4, 60,4, 63,4,
        67,1, 72,1, 75,2, 79,4, 84,4, 87,4,
        91,2, 87,2, 84,4, 79,4, 75,4,
        72,1, 75,1, 79,1, 84,1, 87,2, 84,2, 79,2, 75,4,
        72,2, 67,2, 63,4, 60,4, 63,4,
        67,2, 72,2, 75,4, 79,4, 84,4,
        87,2, 91,2, 96,4, 91,4, 87,4,
        84,1, 79,1, 75,2, 72,4, 67,4, 63,4,
        60,2, 63,2, 67,4, 72,4, 67,4,
        63,1, 67,1, 72,2, 75,4, 79,4,
        84,4, 79,4, 75,4, 72,4,
      ], 0),
      counterSeq: _tp(_rep([
        48,1, 51,1, 55,1, 60,1, 55,1, 51,1, 48,1, 51,1,
        51,1, 55,1, 58,1, 63,1, 58,1, 55,1, 51,1, 55,1,
        46,1, 50,1, 53,1, 58,1, 53,1, 50,1, 46,1, 50,1,
        55,1, 59,1, 62,1, 67,1, 62,1, 59,1, 55,1, 59,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,2,2,2, 1,2,1,2, 2,2,1,2, 1,2,2,4], 7),
        1,2,1,2, 1,2,1,2, 2,2,2,2, 17,0,8,0,
        ..._rep([1,2,2,2, 1,2,2,4, 1,2,1,2, 2,2,2,2], 7),
        2,2,1,2, 1,2,2,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 19, leadPreset: 80, bassPreset: 38,
      counterPreset: 62,
      padVel: 68, leadVel: 108, bassVel: 100, counterVel: 58,
      kickVel: 112, snareVel: 98, hatVel: 75,
    );
  }

  // BOSS 14 — electric fury, D# minor, 158 BPM
  Uint8List _mkBoss14() {
    return _renderSf(
      bpm: 158,
      padSeq: _tpad(_rep([51,1,16, 54,0,16, 58,0,16, 46,4,16], 4), 0),
      bassSeq: _tp(_rep([
        27,1, 27,1, 39,2, 27,2, 27,1, 39,1, 27,1, 27,2,
        30,1, 30,1, 42,2, 30,2, 30,1, 42,1, 30,1, 30,2,
        25,1, 25,1, 37,2, 25,2, 25,1, 37,1, 25,1, 25,2,
        34,1, 34,1, 46,2, 34,2, 34,1, 46,1, 34,1, 34,2,
      ], 4), 0),
      leadSeq: _tp([
        75,2, 78,2, 82,4, 87,4, 82,4,
        78,1, 75,1, 70,2, 66,4, 63,4, 66,4,
        70,2, 75,2, 78,4, 82,4, 87,4,
        90,2, 87,2, 82,4, 78,4, 75,4,
        70,1, 75,1, 78,2, 82,2, 87,2, 90,4, 87,4,
        82,2, 78,2, 75,4, 70,4, 66,4,
        63,2, 66,2, 70,4, 75,4, 78,4,
        82,2, 87,2, 90,4, 87,4, 82,4,
        90,1, 94,1, 97,2, 94,2, 90,2, 87,4,
        82,2, 78,2, 75,4, 78,4, 82,4,
        87,4, 82,4, 78,4, 75,4,
        70,2, 66,2, 63,4, 66,4, 70,4,
        75,2, 78,2, 82,4, 87,4, 82,4,
        78,1, 75,1, 70,2, 66,4, 63,4, 66,4,
        70,2, 75,2, 78,4, 75,4, 70,4,
        66,4, 70,4, 75,4, 78,4,
      ], 0),
      counterSeq: _tp(_rep([
        51,1, 54,1, 58,1, 63,1, 58,1, 54,1, 51,1, 54,1,
        54,1, 58,1, 61,1, 66,1, 61,1, 58,1, 54,1, 58,1,
        49,1, 53,1, 56,1, 61,1, 56,1, 53,1, 49,1, 53,1,
        58,1, 62,1, 65,1, 70,1, 65,1, 62,1, 58,1, 62,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,2,2,4, 1,4,2,2, 1,4,2,4], 7),
        1,2,1,2, 2,4,1,4, 2,2,2,2, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,1,2, 1,4,2,4, 1,2,2,4], 7),
        2,2,1,2, 2,2,1,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 81, leadPreset: 25, bassPreset: 33,
      counterPreset: 46,
      padVel: 72, leadVel: 100, bassVel: 96, counterVel: 55,
      kickVel: 105, snareVel: 92, hatVel: 68,
    );
  }

  // BOSS 15 — berserker rage, E minor high, 172 BPM
  Uint8List _mkBoss15() {
    return _renderSf(
      bpm: 172,
      padSeq: _tpad(_rep([52,1,16, 55,0,16, 59,0,16, 47,4,16], 4), 0),
      bassSeq: _tp(_rep([
        28,1, 28,1, 28,1, 40,1, 28,2, 28,1, 40,1, 28,2,
        31,1, 31,1, 31,1, 43,1, 31,2, 31,1, 43,1, 31,2,
        26,1, 26,1, 26,1, 38,1, 26,2, 26,1, 38,1, 26,2,
        23,1, 23,1, 23,1, 35,1, 23,2, 23,1, 35,1, 23,2,
      ], 4), 0),
      leadSeq: _tp([
        76,1, 79,1, 83,1, 88,1, 91,2, 88,2, 83,2, 79,2,
        76,2, 71,2, 67,4, 64,4,
        76,1, 79,1, 83,2, 88,4, 91,2, 95,2, 91,4,
        88,2, 83,2, 79,4, 76,4,
        91,1, 95,1, 100,2, 95,2, 91,2, 88,2, 83,4,
        79,1, 76,1, 71,2, 67,4, 64,4, 67,4,
        71,1, 76,1, 79,2, 83,4, 88,4, 91,4,
        95,2, 91,2, 88,4, 83,4, 79,4,
        76,1, 79,1, 83,1, 88,1, 91,2, 88,2, 83,2, 79,4,
        76,2, 71,2, 67,4, 64,4, 67,4,
        71,2, 76,2, 79,4, 83,4, 88,4,
        91,2, 95,2, 100,4, 95,4, 91,4,
        88,1, 83,1, 79,2, 76,4, 71,4, 67,4,
        64,2, 67,2, 71,4, 76,4, 71,4,
        67,1, 71,1, 76,2, 79,4, 83,4,
        88,4, 83,4, 79,4, 76,4,
      ], 0),
      counterSeq: _tp(_rep([
        52,1, 55,1, 59,1, 64,1, 59,1, 55,1, 52,1, 55,1,
        55,1, 59,1, 62,1, 67,1, 62,1, 59,1, 55,1, 59,1,
        50,1, 54,1, 57,1, 62,1, 57,1, 54,1, 50,1, 54,1,
        47,1, 51,1, 54,1, 59,1, 54,1, 51,1, 47,1, 51,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,2,2,2, 1,2,1,2, 2,4,1,2, 1,2,2,2], 7),
        1,2,1,2, 1,2,1,2, 2,2,2,2, 17,0,8,0,
        ..._rep([1,2,2,2, 1,4,1,2, 1,2,2,2, 1,2,2,4], 7),
        2,2,1,2, 2,2,1,2, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 29, leadPreset: 81, bassPreset: 38,
      counterPreset: 60,
      padVel: 70, leadVel: 110, bassVel: 100, counterVel: 55,
      kickVel: 112, snareVel: 98, hatVel: 72,
    );
  }

  // BOSS 16 — final stand, A# minor, 152 BPM
  Uint8List _mkBoss16() {
    return _renderSf(
      bpm: 152,
      padSeq: _tpad(_rep([58,1,16, 61,0,16, 53,0,16, 49,4,16], 4), 0),
      bassSeq: _tp(_rep([
        34,1, 34,2, 46,2, 34,2, 34,1, 46,2, 34,1, 34,2,
        37,1, 37,2, 49,2, 37,2, 37,1, 49,2, 37,1, 37,2,
        32,1, 32,2, 44,2, 32,2, 32,1, 44,2, 32,1, 32,2,
        29,1, 29,2, 41,2, 29,2, 29,1, 41,2, 29,1, 29,2,
      ], 4), 0),
      leadSeq: _tp([
        82,4, 85,4, 89,4, 94,4,
        89,2, 85,2, 82,4, 77,4, 73,4,
        82,2, 85,2, 89,4, 94,4, 97,4,
        94,2, 89,2, 85,4, 82,4, 77,4,
        73,2, 77,2, 82,4, 85,4, 89,4,
        94,2, 97,2, 101,4, 97,4, 94,4,
        89,2, 85,2, 82,4, 77,4, 73,4,
        70,2, 73,2, 77,4, 82,4, 77,4,
        94,2, 97,2, 101,4, 97,4, 94,4,
        89,2, 85,2, 82,4, 85,4, 89,4,
        94,4, 89,4, 85,4, 82,4,
        77,2, 73,2, 70,4, 73,4, 77,4,
        82,2, 85,2, 89,4, 94,4, 89,4,
        85,2, 82,2, 77,4, 73,4, 70,4,
        73,4, 77,4, 82,4, 77,4,
        73,4, 70,4, 73,4, 77,4,
      ], 0),
      counterSeq: _tp(_rep([
        58,1, 61,1, 65,1, 70,1, 65,1, 61,1, 58,1, 61,1,
        61,1, 65,1, 68,1, 73,1, 68,1, 65,1, 61,1, 65,1,
        56,1, 60,1, 63,1, 68,1, 63,1, 60,1, 56,1, 60,1,
        53,1, 57,1, 60,1, 65,1, 60,1, 57,1, 53,1, 57,1,
      ], 4), 0),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,2,4, 1,4,4,2], 7),
        1,2,1,2, 2,4,1,4, 2,4,2,4, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,4,2, 1,4,2,4], 7),
        2,4,1,4, 2,4,2,4, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 90, leadPreset: 56, bassPreset: 34,
      counterPreset: 46,
      padVel: 75, leadVel: 98, bassVel: 95, counterVel: 52,
      kickVel: 105, snareVel: 92, hatVel: 62,
    );
  }

  // LAVA (lvl6) — dramatic, urgent. Dm - Bbmaj7 - C - A7. 140 BPM.
  Uint8List _mkLava({int transpose = 0, double bpm = 140}) {
    return _renderSf(
      bpm: bpm,
      padSeq: _tpad(_rep([50,1,16, 46,2,16, 48,0,16, 45,4,16], 4), transpose),
      bassSeq: _tp(_rep([
        38,1, 38,1, 38,2, 45,2, 38,2, 34,2, 34,2, 41,2, 34,2,
        36,2, 36,2, 43,2, 36,2, 45,1, 45,1, 45,2, 52,2, 45,2,
      ], 8), transpose),
      leadSeq: _tp([
        // A: dramatic, driving
        74,2, 77,2, 81,4, 80,2, 77,2, 74,4,
        77,2, 81,2, 82,4, 81,2, 77,2, 74,4,
        79,2, 82,2, 84,4, 82,2, 79,2, 76,4,
        81,4, 77,4, 74,4, 73,4,
        // A repeat
        74,2, 77,2, 81,4, 80,2, 77,2, 74,4,
        77,2, 81,2, 82,4, 81,2, 77,2, 74,4,
        79,2, 82,2, 84,4, 82,2, 79,2, 76,4,
        81,4, 77,4, 74,4, 73,4,
        // B: even more intense, then dramatic resolution
        77,2, 81,2, 82,4, 81,2, 77,2, 74,4,
        82,2, 81,2, 77,4, 74,4, 72,4,
        72,2, 74,2, 77,4, 79,4, 77,4,
        81,4, 77,2, 74,2, 73,4, 74,4,
        74,2, 77,2, 81,2, 82,2, 81,4, 77,4,
        82,4, 81,4, 79,4, 77,4,
        79,2, 77,2, 74,4, 72,4, 74,4,
        81,4, 77,4, 74,4, 73,4,
      ], transpose),
      counterSeq: _tp(_rep([
        50,2, 53,2, 57,2, 53,2, 50,2, 53,2, 57,2, 53,2,
        46,2, 50,2, 53,2, 50,2, 46,2, 50,2, 53,2, 50,2,
        48,2, 52,2, 55,2, 52,2, 48,2, 52,2, 55,2, 52,2,
        45,2, 49,2, 52,2, 49,2, 45,2, 49,2, 52,2, 49,2,
      ], 4), transpose),
      drumPat: [
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,4,2, 1,4,2,4], 7),
        1,2,1,2, 2,4,1,4, 2,4,2,4, 17,0,8,0,
        ..._rep([1,4,2,4, 1,4,2,4, 1,4,2,4, 1,4,4,2], 7),
        2,4,1,4, 2,4,2,4, 1,2,1,2, 17,0,0,0,
      ],
      padPreset: 61, leadPreset: 56, bassPreset: 38,
      counterPreset: 60,
      padVel: 62, leadVel: 95, bassVel: 88, counterVel: 55,
      kickVel: 95, snareVel: 82,
    );
  }
}
