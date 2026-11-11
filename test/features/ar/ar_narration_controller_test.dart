import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ar_narration.dart';
import 'package:netlearn/features/ar/ar_narration_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the controller asks for, and can pretend a file was never
/// recorded exactly like a missing asset does on device.
class _FakeNarrationPlayer implements ArNarrationPlayer {
  _FakeNarrationPlayer({this.missing = const <String>{}});

  final Set<String> missing;
  final List<String> played = <String>[];
  int stops = 0;
  int pauses = 0;
  int resumes = 0;
  bool disposed = false;

  @override
  Future<void> playAsset(String assetPath) async {
    if (missing.contains(assetPath)) {
      throw Exception('missing asset');
    }

    played.add(assetPath);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> pause() async {
    pauses++;
  }

  @override
  Future<void> resume() async {
    resumes++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _completeController.close();
  }

  final StreamController<void> _completeController =
      StreamController<void>.broadcast();

  /// Pretends the current clip reached its end, as `audioplayers` reports.
  void finishClip() => _completeController.add(null);

  @override
  Stream<void> get onComplete => _completeController.stream;
}

const Duration _delay = Duration(milliseconds: 20);

ArNarrationController _controller(_FakeNarrationPlayer player) {
  final ArNarrationController controller =
      ArNarrationController(player: player, delay: _delay);

  addTearDown(controller.dispose);

  return controller;
}

/// Lets the queued timer fire.
Future<void> _settle() => Future<void>.delayed(
      const Duration(milliseconds: 60),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('speak waits for the detection delay before playing', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    controller.speak(ArNarrationClip.komputer, language: 'id');

    expect(
      player.played,
      isEmpty,
      reason: 'the one-second pause keeps the voice from starting while the '
          'camera is still settling on the marker',
    );

    await _settle();

    expect(player.played, ['assets/audio/ar/marker_01_komputer_id.mp3']);
  });

  test('a newer detection replaces the queued clip and stops the old one',
      () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    controller.speak(ArNarrationClip.komputer, language: 'id');
    controller.speak(ArNarrationClip.router, language: 'id');

    await _settle();

    expect(player.played, ['assets/audio/ar/marker_04_router_id.mp3']);
    expect(player.stops, greaterThanOrEqualTo(1));
  });

  test('stop cancels a queued clip', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    controller.speak(ArNarrationClip.komputer, language: 'id');
    controller.stop();

    await _settle();

    expect(player.played, isEmpty);
  });

  test('replay plays immediately and ignores the delay', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    await controller.replay(ArNarrationClip.hub, language: 'id');

    expect(player.played, ['assets/audio/ar/marker_03_hub_id.mp3']);
  });

  test('mute blocks both auto-play and replay', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    await controller.setMuted(true);
    controller.speak(ArNarrationClip.komputer, language: 'id');
    await controller.replay(ArNarrationClip.komputer, language: 'id');
    await _settle();

    expect(player.played, isEmpty);
  });

  test('the mute choice is persisted across sessions', () async {
    final first = _controller(_FakeNarrationPlayer());

    await first.setMuted(true);

    final second = _controller(_FakeNarrationPlayer());
    expect(second.muted.value, isFalse);

    await second.loadPreference();

    expect(second.muted.value, isTrue);
  });

  test('an unrecorded English clip falls back to the Indonesian one', () async {
    const String english = 'assets/audio/ar/marker_01_komputer_en.mp3';
    final player = _FakeNarrationPlayer(missing: <String>{english});
    final controller = _controller(player);

    await controller.replay(ArNarrationClip.komputer, language: 'en');

    expect(player.played, ['assets/audio/ar/marker_01_komputer_id.mp3']);
  });

  test('a clip missing in both languages stays silent instead of throwing',
      () async {
    final player = _FakeNarrationPlayer(
      missing: <String>{
        'assets/audio/ar/marker_01_komputer_en.mp3',
        'assets/audio/ar/marker_01_komputer_id.mp3',
      },
    );
    final controller = _controller(player);

    await controller.replay(ArNarrationClip.komputer, language: 'en');

    expect(player.played, isEmpty);
  });

  test('unmuting continues the paused clip instead of restarting it', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    await controller.replay(ArNarrationClip.komputer, language: 'id');
    player.played.clear();

    await controller.setMuted(true);
    await controller.setMuted(false);

    expect(player.pauses, 1, reason: 'mute pauses the clip at its position');
    expect(player.resumes, 1, reason: 'unmute continues where it was cut');
    expect(
      player.played,
      isEmpty,
      reason: 'a paused clip must not be replayed from the start',
    );
  });

  test('mute while nothing plays does not resume anything', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    await controller.setMuted(true);
    await controller.setMuted(false);

    expect(player.pauses, 0);
    expect(player.resumes, 0);
    expect(player.played, isEmpty);
  });

  test('unmuting plays the clip that arrived while muted', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    await controller.setMuted(true);
    controller.speak(ArNarrationClip.router, language: 'id');
    await controller.setMuted(false);

    expect(player.played, ['assets/audio/ar/marker_04_router_id.mp3']);
  });

  test('muting during the detection delay still restores on unmute', () async {
    final player = _FakeNarrationPlayer();
    // Long delay: the point is that the queued clip is remembered, not that a
    // timer happens to fire first.
    final controller = ArNarrationController(
      player: player,
      delay: const Duration(seconds: 5),
    );
    addTearDown(controller.dispose);

    controller.speak(ArNarrationClip.hub, language: 'id');
    await controller.setMuted(true);
    await controller.setMuted(false);

    expect(player.played, ['assets/audio/ar/marker_03_hub_id.mp3']);
  });

  test('unmuting stays silent once the clip has finished', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    await controller.replay(ArNarrationClip.komputer, language: 'id');
    player.played.clear();
    player.finishClip();
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await controller.setMuted(true);
    await controller.setMuted(false);

    expect(player.played, isEmpty);
  });

  test('a rescan clears the clip unmute would restore', () async {
    final player = _FakeNarrationPlayer();
    final controller = _controller(player);

    await controller.replay(ArNarrationClip.komputer, language: 'id');
    player.played.clear();

    await controller.setMuted(true);
    controller.stop();
    await controller.setMuted(false);

    expect(player.played, isEmpty);
    expect(player.resumes, 0);
  });

  test('dispose drops a queued clip and releases the player', () async {
    final player = _FakeNarrationPlayer();
    final controller =
        ArNarrationController(player: player, delay: _delay);

    controller.speak(ArNarrationClip.komputer, language: 'id');
    controller.dispose();

    await _settle();

    expect(player.played, isEmpty);
    expect(player.disposed, isTrue);
  });
}
