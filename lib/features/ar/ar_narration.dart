import 'package:flutter/foundation.dart';

import 'ar_lab_scene.dart';
import 'ar_marker_catalog.dart';

/// One recorded narration clip.
///
/// The AR plugin offers almost no reliable on-object interaction (see the AR-10
/// deviation in `AR_PRD.md`), so narration is the main way an object "explains
/// itself": Modul 1–3 auto-play on detection, Modul 4 speaks the tapped device
/// and the connection-test result. Keeping the clip identities here — free of
/// Flutter widgets, AR sessions and Supabase — lets the whole mapping be
/// asserted offline.
enum ArNarrationClip {
  komputer,
  switchDevice,
  hub,
  router,
  topologi,
  labComputerA,
  labComputerB,
  labSwitch,
  labCable,
  labTestSuccess,
  labTestFailure,
}

/// The app ships exactly two locales, so anything that is not `en` is treated
/// as Indonesian. This also keeps a device locale like `en-GB` on English.
String arNarrationLanguage(String languageCode) =>
    languageCode == 'en' ? 'en' : 'id';

/// Maps each [ArNarrationClip] to its base `<clip>` filename prefix.
///
/// All bundled MP3 assets in `assets/audio/ar/` follow `<clip>_<lang>.mp3`
/// uniformly across Indonesian (`_id`) and English (`_en`).
String _baseName(ArNarrationClip clip) {
  switch (clip) {
    case ArNarrationClip.komputer:
      return 'marker_01_komputer';
    case ArNarrationClip.switchDevice:
      return 'marker_02_switch';
    case ArNarrationClip.hub:
      return 'marker_03_hub';
    case ArNarrationClip.router:
      return 'marker_04_router';
    case ArNarrationClip.topologi:
      return 'marker_05_topologi';
    case ArNarrationClip.labComputerA:
      return 'lab_komputer_a';
    case ArNarrationClip.labComputerB:
      return 'lab_komputer_b';
    case ArNarrationClip.labSwitch:
      return 'lab_switch';
    case ArNarrationClip.labCable:
      return 'lab_kabel_utp';
    case ArNarrationClip.labTestSuccess:
      return 'lab_uji_berhasil';
    case ArNarrationClip.labTestFailure:
      return 'lab_uji_gagal';
  }
}

/// Flutter asset path for [clip] in [language].
///
/// The `assets/audio/ar/` folder is declared in `pubspec.yaml`; the file name
/// has to match the recording convention exactly, otherwise the asset silently
/// fails to bundle (the entry is not recursive).
String arNarrationAssetPath(
  ArNarrationClip clip, {
  required String language,
}) {
  final String code = arNarrationLanguage(language);

  return 'assets/audio/ar/${_baseName(clip)}_$code.mp3';
}

/// Indonesian clip to use when the active language's recording is missing.
///
/// Recordings arrive one at a time, so an untranslated clip must not silence
/// the object entirely. Returns `null` when the clip *is* the Indonesian one.
String? arNarrationFallbackAssetPath(
  ArNarrationClip clip, {
  required String language,
}) {
  if (arNarrationLanguage(language) == 'id') {
    return null;
  }

  return arNarrationAssetPath(clip, language: 'id');
}

/// Auto-play clip for a detected marker.
///
/// Modul 4 (`ipAddress`) builds the lab scene instead of a single object, so it
/// has no marker-level narration: its clips are triggered by the device tap and
/// by the connection test.
ArNarrationClip? arNarrationForMarker(ArMarkerId id) {
  switch (id) {
    case ArMarkerId.komputer:
      return ArNarrationClip.komputer;
    case ArMarkerId.switchDevice:
      return ArNarrationClip.switchDevice;
    case ArMarkerId.hub:
      return ArNarrationClip.hub;
    case ArMarkerId.router:
      return ArNarrationClip.router;
    case ArMarkerId.topologi:
      return ArNarrationClip.topologi;
    case ArMarkerId.ipAddress:
      return null;
  }
}

/// Clip spoken when a lab computer is tapped in Modul 4.
///
/// Only computers are selectable (`ArLabDevice` has exactly two values), which
/// is why there is no device clip for the switch here. `labSwitch` is spoken
/// when the lab appears and `labCable` waits for a control that can target the
/// cable without the unreliable 3D tap path.
ArNarrationClip arNarrationForLabDevice(ArLabDevice device) {
  switch (device) {
    case ArLabDevice.pcA:
      return ArNarrationClip.labComputerA;
    case ArLabDevice.pcB:
      return ArNarrationClip.labComputerB;
  }
}

/// Every clip the catalog knows, in recording order. Used by tests and by the
/// missing-file log so a half-recorded set is visible in one place.
@visibleForTesting
const List<ArNarrationClip> arNarrationClips = <ArNarrationClip>[
  ArNarrationClip.komputer,
  ArNarrationClip.switchDevice,
  ArNarrationClip.hub,
  ArNarrationClip.router,
  ArNarrationClip.topologi,
  ArNarrationClip.labComputerA,
  ArNarrationClip.labComputerB,
  ArNarrationClip.labSwitch,
  ArNarrationClip.labCable,
  ArNarrationClip.labTestSuccess,
  ArNarrationClip.labTestFailure,
];
