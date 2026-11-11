import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ar_narration.dart';

/// Minimal playback surface the narration controller needs.
///
/// Extracted so tests can drive the "auto-play after 1 s", mute and
/// language-fallback rules without an audio plugin or a device.
abstract class ArNarrationPlayer {
  /// Starts [assetPath] from the start, replacing anything already playing.
  Future<void> playAsset(String assetPath);

  Future<void> stop();

  /// Holds the current clip at its position. Used by mute so unmuting can
  /// continue the sentence instead of restarting it.
  Future<void> pause();

  /// Continues a clip paused with [pause].
  Future<void> resume();

  Future<void> dispose();

  /// Emits once every time a clip reaches its end. The controller uses it to
  /// know whether muting actually cut something short, so unmuting restores the
  /// voice only when there was something to restore.
  Stream<void> get onComplete;
}

/// Real implementation backed by `audioplayers`.
class AudioPlayersNarrationPlayer implements ArNarrationPlayer {
  AudioPlayersNarrationPlayer() : _player = AudioPlayer() {
    // The default `ReleaseMode.release` tears the native player down after every
    // clip; a stop()/play() pair around that teardown can leave the player
    // silent on the next request. Keeping it alive makes repeated narration
    // (and mute/unmute cycles) reliable.
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  final AudioPlayer _player;

  @override
  Future<void> playAsset(String assetPath) async {
    // `AssetSource` paths are relative to `assets/`; the catalog keeps the full
    // asset path because that is what pubspec declares and what reads clearly.
    final String relative =
        assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;

    await _player.stop();
    await _player.play(AssetSource(relative));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> dispose() => _player.dispose();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;
}

/// Plays the recorded object narrations for the AR scanner.
///
/// Behaviour agreed for the feature:
/// - auto-play starts after [delay] (one second), so the voice does not begin
///   while the camera is still settling on the marker;
/// - starting a clip always stops the previous one — the page never layers two
///   narrations;
/// - the mute switch is persisted, so a student in a quiet classroom is not
///   surprised by the next session;
/// - mute is a *pause*, not a stop: unmuting continues the sentence where it
///   was cut instead of restarting it, and a clip requested while muted is
///   played when sound returns;
/// - when the active language's file has not been recorded yet, the Indonesian
///   file is used instead of silence.
///
/// It is a plain object rather than a Riverpod notifier because the AR page is a
/// `StatefulWidget` and owns the controller for exactly one AR session.
class ArNarrationController {
  ArNarrationController({
    ArNarrationPlayer? player,
    this.delay = const Duration(seconds: 1),
  }) : _player = player ?? AudioPlayersNarrationPlayer() {
    _completeSubscription = _player.onComplete.listen((_) {
      _playing = false;
    });
  }

  static const String mutedPreferenceKey = 'netlearn_ar_narration_muted';

  final ArNarrationPlayer _player;

  /// Pause between detection and the voice (one second in the app).
  final Duration delay;

  /// Read by the page's mute button. `ValueNotifier` instead of `setState` so
  /// the toggle does not rebuild the whole AR stack (platform view included).
  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  Timer? _pending;
  late final StreamSubscription<void> _completeSubscription;
  bool _disposed = false;

  /// Whether a clip is playing right now, tracked from the player's completion
  /// event. `stop()` clears it eagerly because the platform never reports
  /// completion for an interrupted clip.
  bool _playing = false;

  /// Whether the current clip is held at its position by mute. `resume()` on
  /// unmute then continues from there instead of starting over.
  bool _paused = false;

  /// A clip requested while muted (marker scanned or "listen again" pressed).
  /// Muting is often toggled *before* pointing at an object, so this is the
  /// most relevant thing to play when sound returns.
  ({ArNarrationClip clip, String language})? _suppressedWhileMuted;

  /// The clip waiting out the detection delay. Muting during that window counts
  /// as interrupted too, so unmute still speaks it.
  ({ArNarrationClip clip, String language})? _pendingClip;

  /// The clip that had not started yet when mute was pressed (still inside the
  /// detection delay). A clip that *was* audible is paused, not replayed, so it
  /// is not stored here.
  ({ArNarrationClip clip, String language})? _interruptedByMute;

  /// Loads the persisted mute choice. Fire-and-forget from `initState`; the
  /// page works with the default (unmuted) until it resolves.
  Future<void> loadPreference() async {
    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    muted.value = preferences.getBool(mutedPreferenceKey) ?? false;
  }

  Future<void> setMuted(bool value) async {
    muted.value = value;

    if (value) {
      // A clip still waiting out the detection delay has not reached the player
      // yet, so it cannot be paused — remember it and start it on unmute.
      _interruptedByMute = _pendingClip;
      _cancelPending();

      if (_playing) {
        // Pause, not stop: the position survives, so unmuting continues the
        // sentence instead of restarting it from the beginning.
        _paused = true;
        await _player.pause();
      } else {
        await _player.stop();
      }
    } else {
      // Sound coming back should also bring the voice back. Priority: a clip the
      // user asked for while muted, then the paused sentence, then a clip that
      // never got past the detection delay.
      final ({ArNarrationClip clip, String language})? suppressed =
          _suppressedWhileMuted;
      final ({ArNarrationClip clip, String language})? unstarted =
          _interruptedByMute;

      _suppressedWhileMuted = null;
      _interruptedByMute = null;

      if (suppressed != null) {
        await _play(suppressed.clip, language: suppressed.language);
      } else if (_paused && !_disposed) {
        _paused = false;
        await _player.resume();
      } else if (unstarted != null && !_disposed) {
        await _play(unstarted.clip, language: unstarted.language);
      }
    }

    final SharedPreferences preferences =
        await SharedPreferences.getInstance();

    await preferences.setBool(mutedPreferenceKey, value);
  }

  Future<void> toggleMuted() => setMuted(!muted.value);

  /// Queues [clip] to start after the detection delay.
  ///
  /// A new call replaces the queued clip, so moving the camera from one marker
  /// to another only ever narrates the last one. Does nothing while muted.
  void speak(ArNarrationClip clip, {required String language}) {
    _cancelPending();
    unawaited(_player.stop());
    _playing = false;
    _paused = false;

    if (muted.value) {
      // Scanning while muted is normal (quiet classroom). Hold the request so
      // unmuting still explains the object that is on screen.
      _suppressedWhileMuted = (clip: clip, language: language);

      return;
    }

    _pendingClip = (clip: clip, language: language);

    _pending = Timer(delay, () {
      _pending = null;
      _pendingClip = null;

      if (_disposed || muted.value) {
        return;
      }

      unawaited(_play(clip, language: language));
    });
  }

  /// Plays [clip] immediately. Used by the replay button and the Modul 4 device
  /// taps, where the user has already pointed at the object.
  Future<void> replay(
    ArNarrationClip clip, {
    required String language,
  }) async {
    _cancelPending();

    if (muted.value) {
      _suppressedWhileMuted = (clip: clip, language: language);

      return;
    }

    await _play(clip, language: language);
  }

  /// Drops the queued clip and stops playback. Called when the page leaves the
  /// detected state (rescan, marker switch, teardown).
  void stop() {
    _cancelPending();
    _playing = false;
    _paused = false;
    _suppressedWhileMuted = null;
    _interruptedByMute = null;
    unawaited(_player.stop());
  }

  Future<void> _play(
    ArNarrationClip clip, {
    required String language,
  }) async {
    final String primary =
        arNarrationAssetPath(clip, language: language);

    try {
      await _player.playAsset(primary);
      _markPlaying();

      return;
    } catch (error) {
      // A missing/unrecorded file is expected while the set is being recorded;
      // fall through to the Indonesian clip instead of failing silently.
      final String? fallback =
          arNarrationFallbackAssetPath(clip, language: language);

      if (fallback == null) {
        debugPrint('[ar-narration] could not play $primary: $error');

        return;
      }

      try {
        await _player.playAsset(fallback);
        // Remember the *requested* language, not the Indonesian fallback, so a
        // replay goes through the same fallback chain again.
        _markPlaying();
      } catch (fallbackError) {
        debugPrint('[ar-narration] could not play $fallback: $fallbackError');
      }
    }
  }

  void _markPlaying() {
    _playing = true;
    _paused = false;
  }

  void _cancelPending() {
    _pending?.cancel();
    _pending = null;
    _pendingClip = null;
  }

  void dispose() {
    _disposed = true;
    _cancelPending();
    unawaited(_completeSubscription.cancel());
    unawaited(_player.dispose());
    muted.dispose();
  }
}
