import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sound Effects (SFX) service for interactive audio feedback across NetLearn.
class SfxService {
  SfxService._();
  static final SfxService instance = SfxService._();

  static const String _prefKey = 'netlearn_sfx_enabled';
  bool _enabled = true;
  AudioPlayer? _player;

  bool get isEnabled => _enabled;

  /// Initializes the SFX service and loads sound preference.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? true;
    } catch (e) {
      debugPrint('SfxService init error: $e');
    }
  }

  /// Toggles sound effects on/off.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  Future<void> _play(String assetPath) async {
    if (!_enabled) return;
    try {
      _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      // audioplayers AssetSource expects path relative to assets folder
      await _player!.stop();
      await _player!.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('SfxService play error ($assetPath): $e');
    }
  }

  /// Snappy pop sound for buttons, tabs, selection.
  Future<void> playPop() => _play('audio/sfx/pop.wav');

  /// Pleasant major chord chime for correct answers, quiz submit, ping success, badge unlock.
  Future<void> playSuccess() => _play('audio/sfx/success.wav');

  /// Mechanical snap/click when cable is plugged into a switch port in Virtual Lab.
  Future<void> playConnect() => _play('audio/sfx/connect.wav');

  /// Soft low thud for wrong answers or ping failure.
  Future<void> playError() => _play('audio/sfx/error.wav');

  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
