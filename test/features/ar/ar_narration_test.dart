import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/ar/ar_lab_scene.dart';
import 'package:netlearn/features/ar/ar_marker_catalog.dart';
import 'package:netlearn/features/ar/ar_narration.dart';

void main() {
  group('marker clips', () {
    test('every single-object marker has a clip', () {
      expect(arNarrationForMarker(ArMarkerId.komputer),
          ArNarrationClip.komputer);
      expect(arNarrationForMarker(ArMarkerId.switchDevice),
          ArNarrationClip.switchDevice);
      expect(arNarrationForMarker(ArMarkerId.hub), ArNarrationClip.hub);
      expect(arNarrationForMarker(ArMarkerId.router), ArNarrationClip.router);
      expect(arNarrationForMarker(ArMarkerId.topologi),
          ArNarrationClip.topologi);
    });

    test('Modul 4 has no marker clip; its narration is per device', () {
      expect(arNarrationForMarker(ArMarkerId.ipAddress), isNull);
    });

    test('the two lab computers map to their own clips', () {
      expect(arNarrationForLabDevice(ArLabDevice.pcA),
          ArNarrationClip.labComputerA);
      expect(arNarrationForLabDevice(ArLabDevice.pcB),
          ArNarrationClip.labComputerB);
    });
  });

  group('asset paths', () {
    test('use the recording convention <clip>_<language>.mp3', () {
      expect(
        arNarrationAssetPath(ArNarrationClip.komputer, language: 'id'),
        'assets/audio/ar/marker_01_komputer_id.mp3',
      );
      expect(
        arNarrationAssetPath(ArNarrationClip.komputer, language: 'en'),
        'assets/audio/ar/marker_01_komputer_en.mp3',
      );
      expect(
        arNarrationAssetPath(ArNarrationClip.labCable, language: 'id'),
        'assets/audio/ar/lab_kabel_utp_id.mp3',
      );
    });

    test('the test-result clips resolve to bundled en/id MP3 files', () {
      expect(
        arNarrationAssetPath(ArNarrationClip.labTestSuccess, language: 'id'),
        'assets/audio/ar/lab_uji_berhasil_id.mp3',
      );
      expect(
        arNarrationAssetPath(ArNarrationClip.labTestSuccess, language: 'en'),
        'assets/audio/ar/lab_uji_berhasil_en.mp3',
      );
      expect(
        arNarrationAssetPath(ArNarrationClip.labTestFailure, language: 'id'),
        'assets/audio/ar/lab_uji_gagal_id.mp3',
      );
      expect(
        arNarrationAssetPath(ArNarrationClip.labTestFailure, language: 'en'),
        'assets/audio/ar/lab_uji_gagal_en.mp3',
      );
    });

    test('a regional or unknown locale falls back to Indonesian', () {
      expect(arNarrationLanguage('en'), 'en');
      expect(arNarrationLanguage('id'), 'id');
      expect(arNarrationLanguage('en-GB'), 'id');
      expect(arNarrationLanguage('fr'), 'id');
    });

    test('an untranslated English clip falls back to the Indonesian file', () {
      expect(
        arNarrationFallbackAssetPath(
          ArNarrationClip.router,
          language: 'en',
        ),
        'assets/audio/ar/marker_04_router_id.mp3',
      );
      // The Indonesian file is the last resort: nothing to fall back to.
      expect(
        arNarrationFallbackAssetPath(
          ArNarrationClip.router,
          language: 'id',
        ),
        isNull,
      );
    });

    test('every clip resolves to a unique path in each language', () {
      for (final String language in <String>['id', 'en']) {
        final List<String> paths = arNarrationClips
            .map((clip) =>
                arNarrationAssetPath(clip, language: language))
            .toList();

        expect(paths.toSet(), hasLength(arNarrationClips.length));
        expect(
          paths.every((path) => path.startsWith('assets/audio/ar/')),
          isTrue,
        );
      }
    });

    test('every AR narration MP3, marker PNG, and 3D GLB exists on disk', () {
      for (final String language in <String>['id', 'en']) {
        for (final clip in arNarrationClips) {
          final path = arNarrationAssetPath(clip, language: language);
          expect(
            File(path).existsSync(),
            isTrue,
            reason: 'Missing bundled narration asset: $path',
          );
        }
      }
      for (final marker in arMarkerCatalog) {
        expect(
          File(marker.assetPath).existsSync(),
          isTrue,
          reason: 'Missing marker image: ${marker.assetPath}',
        );
        if (marker.modelPath != null) {
          expect(
            File(marker.modelPath!).existsSync(),
            isTrue,
            reason: 'Missing 3D GLB model: ${marker.modelPath}',
          );
        }
      }
      expect(File(kArLabSceneAsset).existsSync(), isTrue);
      expect(File(kArLabPacketAsset).existsSync(), isTrue);
    });
  });
}
