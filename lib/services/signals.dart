import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';

/// 모스부호 SOS (··· ─── ···). 단위 시간 기준: 점 1, 선 3, 부호 사이 1, 글자 사이 3, 반복 사이 7.
List<(bool, int)> sosPattern() {
  final seq = <(bool, int)>[];
  void letter(List<int> marks) {
    for (var i = 0; i < marks.length; i++) {
      seq.add((true, marks[i]));
      seq.add((false, i < marks.length - 1 ? 1 : 3));
    }
  }

  letter([1, 1, 1]);
  letter([3, 3, 3]);
  letter([1, 1, 1]);
  seq[seq.length - 1] = (false, 7);
  return seq;
}

const _unitMs = 250;

/// 켜고/끄기 콜백으로 SOS 패턴을 반복한다 (손전등·화면 깜빡임 공용).
class MorseRunner {
  final void Function(bool on) apply;
  Timer? _t;
  int _i = 0;
  MorseRunner(this.apply);

  void start() {
    stop();
    final seq = sosPattern();
    void step() {
      final (on, units) = seq[_i % seq.length];
      apply(on);
      _i++;
      _t = Timer(Duration(milliseconds: units * _unitMs), step);
    }

    step();
  }

  void stop() {
    _t?.cancel();
    _t = null;
    _i = 0;
    apply(false);
  }
}

class Signals {
  static MorseRunner? _torch;
  static AudioPlayer? _player;

  static Future<bool> torchAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } catch (_) {
      return false;
    }
  }

  static void startTorch() {
    _torch = MorseRunner((on) {
      (on ? TorchLight.enableTorch() : TorchLight.disableTorch()).catchError((_) {});
    })..start();
  }

  static void stopTorch() {
    _torch?.stop();
    _torch = null;
  }

  static Future<void> startVibration() async {
    try {
      if (!(await Vibration.hasVibrator())) return;
      // [대기, 진동, 대기, 진동 …] — 패턴이 '켜짐'으로 시작하므로 첫 대기는 0
      final pattern = <int>[0, for (final (_, units) in sosPattern()) units * _unitMs];
      await Vibration.vibrate(pattern: pattern, repeat: 0);
    } catch (_) {}
  }

  static void stopVibration() => Vibration.cancel().catchError((_) {});

  /// 경보음: 기기 안에서 만든 고음 사각파를 반복 재생 (파일·네트워크 불필요).
  static Future<void> startAlarm() async {
    try {
      _player ??= AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.play(BytesSource(_alarmWav(), mimeType: 'audio/wav'), volume: 1.0);
    } catch (_) {}
  }

  static void stopAlarm() => _player?.stop().catchError((_) {});

  static Uint8List _alarmWav() {
    const rate = 22050, seconds = 1;
    final n = rate * seconds;
    final data = ByteData(44 + n);
    void str(int o, String s) => s.codeUnits.asMap().forEach((i, c) => data.setUint8(o + i, c));
    str(0, 'RIFF');
    data.setUint32(4, 36 + n, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little); // PCM
    data.setUint16(22, 1, Endian.little); // mono
    data.setUint32(24, rate, Endian.little);
    data.setUint32(28, rate, Endian.little);
    data.setUint16(32, 1, Endian.little);
    data.setUint16(34, 8, Endian.little); // 8-bit
    str(36, 'data');
    data.setUint32(40, n, Endian.little);
    for (var i = 0; i < n; i++) {
      // 2.5~3.5kHz 사이를 오르내리는 사이렌 (사람 귀에 잘 들리는 대역)
      final f = 3000 + 500 * sin(2 * pi * i / rate * 2);
      final v = sin(2 * pi * f * i / rate) >= 0 ? 230 : 25;
      data.setUint8(44 + i, v);
    }
    return data.buffer.asUint8List();
  }
}
